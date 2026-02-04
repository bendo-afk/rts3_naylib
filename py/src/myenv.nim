import nimpy
import raylib, raymath
import ../../src/battle/world
import ../../src/battle/map/[hex_math, tilemap]
import ../../src/battle/unit/unit
import ../../src/battle/system/height_system
import ../../src/battle/rules/match_rule


var worldEnv: World

const
  Vsize = 100
  maxX: int = 19
  maxY: int = 19
  maxHeight = 5

  maxPosX = tile2pos(Vsize, Vector2i(x: maxX, y: 1)).x
  # maxPosY = tile2pos(Vsize, Vector2i(x: 0, y: maxY)).y


proc initEnv(aParams, eParams: seq[MinimalParams]) {.exportpy.} =
  var mRule = MatchRule()

  worldEnv = newWorld(mRule, Vsize, aParams, eParams)


proc setAction(unitId: int, isAlly: bool, moveOrHeight: int, rotateAction: int) {.exportpy.} =
  var u = worldEnv.units[unitId]
  let curTile = worldEnv.map.pos2tile(u.move.pos)
  case moveOrHeight:
    of 0..5:
      let targetTile = getAdjacentTile(curTile, moveOrHeight)
      addPath(u, worldEnv, targetTile)
    of 6:
      discard
    of 7..13:
      var targetTile: Vector2i
      if moveOrHeight == 13:
        targetTile = curTile
      else:
        targetTile = getAdjacentTile(curTile, moveOrHeight - 7)
      worldEnv.heightSystem.tryStart(u, isAlly, targetTile, true)
    of 14..20:
      var targetTile: Vector2i
      if moveOrHeight == 20:
        targetTile = curTile
      else:
        targetTile = getAdjacentTile(curTile, moveOrHeight - 14)
      worldEnv.heightSystem.tryStart(u, isAlly, targetTile, false)
    else:
      discard
  
  var targetAngle: float
  let offset = 0.5
  case rotateAction:
  of 1:
    targetAngle = u.attack.turretAngle + offset
  of 2:
    targetAngle = u.attack.turretAngle - offset
  else:
    targetAngle = u.attack.turretAngle
  let relPos = Vector2(x: cos(targetAngle), y: sin(targetAngle))
  u.attack.targetPos = relPos + u.move.pos


proc fillUnitObs(u: Unit, pos: Vector2): array[14, float32] =
  return [
    pos.x,
    pos.y,
    u.move.movingWeight,
    u.move.speed / 10,
    u.hp.hp / 50,
    u.attack.damage / 10,
    u.attack.traverseSpeed / 10,
    u.attack.maxReloadTime / 10,
    u.attack.leftReloadTime / 10,
    u.attack.turretAngle.cos,
    u.attack.turretAngle.sin,
    u.heightAction.maxTimer / 10,
    u.heightAction.leftTimer / 10,
    u.vision.visibleState.float / 2
  ]


proc getObsOfSelf(unitId: int): array[15, float32] {.exportpy.} =
  let u = worldEnv.units[unitId]
  
  result[0] = u.isDead().float32

  if result[0] == 0:
    let obs = fillUnitObs(u, u.move.pos / maxPosX)
    for i in 0..13: result[i + 1] = obs[i]


proc getObsAlly(selfId, targetId: int): array[15, float32] {.exportpy.} =
  let
    sPos = worldEnv.units[selfId].move.pos
    t = worldEnv.units[targetId]
  result[0] = t.isDead().float32
  if result[0] == 0:
    let obs = fillUnitObs(t, (t.move.pos - sPos) / maxPosX)
    for i in 0..13: result[i+1] = obs[i]


proc getObsEnemy(selfId, targetId: int): array[15, float32] {.exportpy.} =
  let sPos = worldEnv.units[selfId].move.pos
  let t = worldEnv.units[targetId]
  result[0] = t.isDead().float32
  
  if result[0] == 0:
    let vis = t.vision.visibleState
    var targetPos = if vis == visVisible: t.move.pos else: t.vision.lastPosition
    
    var relPos = (targetPos - sPos) / maxPosX
    if vis != visVisible and t.vision.lastPosition.x < -10000.0:
      relPos = Vector2(x: 0, y: 0) 

    let obs = fillUnitObs(t, relPos)
    for i in 0..13: result[i+1] = obs[i]
    
    if vis != visVisible:
      result[3] = 0
      result[10] = 0
      result[11] = 0


proc getObsHeight(): array[maxX + 1, array[maxY + 1, float32]] {.exportpy.} =
  for y in 0..maxY:
    for x in 0..maxX:
      result[x][y] = worldEnv.map.getHeight(Vector2i(x: x, y: y)).float32 / maxHeight.float32


proc getObsUnitsMap(myUnitId: int): array[4, array[maxX + 1, array[maxY + 1, float32]]] {.exportpy.} =
  # result[0]: 自分自身 (1.0)
  # result[1]: 味方 (1.0)
  # result[2]: 敵の現在地 (1.0)
  # result[3]: 敵の最終確認位置 (0.5)

  let
    myUnit = worldEnv.units[myUnitId]
    mySide = myUnit.team
  
  for u in worldEnv.units:
    let tile = worldEnv.map.pos2tile(u.move.pos)

    if u.id == myUnitId:
      result[0][tile.x][tile.y] = 1
    elif u.team == mySide:
      result[1][tile.x][tile.y] += 0.1
    else:
      if u.vision.visibleState == visVisible:
        result[2][tile.x][tile.y] += 0.1
      else:
        # 最後に確認された座標を変換
        if u.vision.lastPosition.x > -10000.0:
          let lastTile = worldEnv.map.pos2tile(u.vision.lastPosition)
          if lastTile.x in 0..maxX and lastTile.y in 0..maxY:
            result[3][lastTile.x][lastTile.y] += 0.1


proc getObsScoreMap(isAlly: bool): array[4, array[maxX + 1, array[maxY + 1, float32]]] {.exportpy.} =
  # result[0]: 味方の残り回数 (正規化)
  # result[1]: 味方の残り時間 (正規化)
  # result[2]: 敵の残り回数 (正規化)
  # result[3]: 敵の残り時間 (正規化)
  let ss = worldEnv.scoreSystem
  
  # 回数と時間の正規化用定数（0除算防止）
  let maxCount: float32 = 5
  let maxInterval: float32 = 30

  # 味方のタイル情報をマップに書き込み
  for t in ss.allyTiles:
    if t.tile.x in 0..maxX and t.tile.y in 0..maxY:
      result[0][t.tile.x][t.tile.y] = t.leftCount.float32 / maxCount
      result[1][t.tile.x][t.tile.y] = t.leftTime / maxInterval

  # 敵のタイル情報をマップに書き込み
  for t in ss.enemyTiles:
    if t.tile.x in 0..maxX and t.tile.y in 0..maxY:
      result[2][t.tile.x][t.tile.y] = t.leftCount.float32 / maxCount
      result[3][t.tile.x][t.tile.y] = t.leftTime / maxInterval


proc getLeftMatchTime(): float32 {.exportpy.} =
  worldEnv.leftMatchTime


proc getReward(unitId: int): float32 {.exportpy.} =
  