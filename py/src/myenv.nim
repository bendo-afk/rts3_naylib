import nimpy
import raylib, raymath
import ../../src/battle/world
import ../../src/battle/map/[hex_math, tilemap]
import ../../src/battle/unit/unit
import ../../src/battle/system/height_system
import ../../src/battle/rules/match_rule as mr
import ../../src/battle/ui/world_ui as wu
import ../../src/camera as cam


var worldEnv: World
var camera: Camera2D
var worldUi: WorldUI

const
  width = 900
  height = 800

const
  Delta = 1 / 60
  Vsize = 100
  maxX: int = 19
  maxY: int = 19
  maxHeight = 5

  maxPosX = tile2pos(Vsize, Vector2i(x: maxX, y: 1)).x
  # maxPosY = tile2pos(Vsize, Vector2i(x: 0, y: maxY)).y

var aParams, eParams: seq[MinimalParams]
var matchRule: MatchRule

var oldScores: array[Team, float32] = [0, 0]
var rewards: array[Team, float32] = [0, 0]


proc initEnv(aParamsArg, eParamsArg: seq[MinimalParams], renderMode: bool) {.exportpy.} =
  matchRule = MatchRule()
  matchRule.maxX = maxX
  matchRule.maxY = maxY
  matchRule.maxHeight = maxHeight

  matchRule.heightCd = 4
  matchRule.scoreInterval = 5
  matchRule.scoreKaisuu = 3
  aParams = aParamsArg
  eParams = eParamsArg

  if renderMode:
    initWindow(width, height, "training")


proc reset() {.exportpy.} =
  worldEnv = newWorld(matchRule, Vsize, aParams, eParams)
  camera = Camera2D(zoom: 1, target: Vector2(x: -100, y: -100), offset: Vector2(x: width / 2, y: height / 2))
  worldUI = initWorldUI(worldEnv)
  oldScores = [0, 0]
  rewards = [0, 0]


proc setAction(unitId: int, moveOrHeight: int, rotateAction: int) {.exportpy.} =
  var u = addr worldEnv.units[unitId]
  let team = u.team
  let curTile = worldEnv.map.pos2tile(u.move.pos)
  case moveOrHeight:
    of 0..5:
      let targetTile = getAdjacentTile(curTile, moveOrHeight)
      addPath(u[], worldEnv, targetTile)
    of 6:
      discard
    of 7..13:
      var targetTile: Vector2i
      if moveOrHeight == 13:
        targetTile = curTile
      else:
        targetTile = getAdjacentTile(curTile, moveOrHeight - 7)
      worldEnv.heightSystem.tryStart(u[], team, targetTile, true)
    of 14..20:
      var targetTile: Vector2i
      if moveOrHeight == 20:
        targetTile = curTile
      else:
        targetTile = getAdjacentTile(curTile, moveOrHeight - 14)
      worldEnv.heightSystem.tryStart(u[], team, targetTile, false)
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


proc isMovable(unitId: int, moveAction: int): bool {.exportpy.} =
  if worldEnv.units[unitId].move.movingWeight != 0:
    return false
  let
    curTile = worldEnv.map.pos2tile(worldEnv.units[unitId].move.pos)
    nextTile = getAdjacentTile(curTile, moveAction)
  return worldEnv.map.isExists(nextTile) and worldEnv.map.isMovable(curTile, nextTile)


proc isChangeable(unitId, hAct: int): bool {.exportpy.} =
  if worldEnv.units[unitId].move.movingWeight != 0:
    return false
  let team = worldEnv.units[unitId].team
  if not worldEnv.heightSystem.canStartAction(team):
    return false

  let isRaise = hAct <= 13
  var targetIdx = if isRaise: hAct - 7 else: hAct - 14
  let curTile = worldEnv.map.pos2tile(worldEnv.units[unitId].move.pos)
  let targetTile = if targetIdx == 6: curTile else: getAdjacentTile(curTile, targetIdx)
  
  return worldEnv.map.isExists(targetTile) and
      worldEnv.map.isMovable(curTile, targetTile) and
      worldEnv.map.canChangeHeight(targetTile, isRaise)


proc getActionMask(unitId: int): array[21, bool] {.exportpy.} =
  for i in 0..5:
    result[i] = isMovable(unitId, i)
  result[6] = true
  for i in 7..20:
    result[i] = isChangeable(unitId, i)


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
  
  let maxCount: float32 = 5
  let maxInterval: float32 = 30

  let
    myTeam = if isAlly: Team.Ally else: Team.Enemy
    oppTeam = if isAlly: Team.Enemy else: Team.Ally
  for t in ss.effTiles[myTeam]:
    if t.tile.x in 0..maxX and t.tile.y in 0..maxY:
      result[0][t.tile.x][t.tile.y] = t.leftCount.float32 / maxCount
      result[1][t.tile.x][t.tile.y] = t.leftTime / maxInterval

  for t in ss.effTiles[oppTeam]:
    if t.tile.x in 0..maxX and t.tile.y in 0..maxY:
      result[2][t.tile.x][t.tile.y] = t.leftCount.float32 / maxCount
      result[3][t.tile.x][t.tile.y] = t.leftTime / maxInterval


proc getLeftMatchTime(): float32 {.exportpy.} =
  worldEnv.leftMatchTime


proc step() {.exportpy.} =
  worldEnv.update(Delta)
  
  for t in Team:
    rewards[t] = worldEnv.scoreSystem.scores[t] - oldScores[t]
    if worldEnv.heightSystem.areChanged[t].isChanged:
      rewards[t] += 1
    rewards[t] *= 0.1

    oldScores[t] = worldEnv.scoreSystem.scores[t]


proc isTerminated(): bool {.exportpy.} =
  return worldEnv.leftMatchTime <= 0


proc getReward(unitId: int): float32 {.exportpy.} =
  let team = worldEnv.units[unitId].team
  return rewards[team]


proc draw() {.exportpy.} =
  if not windowShouldClose():
    dragCamera(camera)
    zoomCamera(camera)

    beginDrawing()
    clearBackground(Brown)

    worldUI.draw(worldEnv, camera)

    drawFPS(1, 1)

    endDrawing()