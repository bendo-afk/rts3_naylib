import sequtils
import arraymancer
import raylib, raymath
import ../battle/world
import ../battle/map/[hex_math, tilemap]
import ../battle/unit/unit
import ../battle/system/height_system
import ../battle/rules/match_rule as mr
import ../battle/ui/world_ui as wu
import ../camera as cam


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



type WorldEnv = object
  renderMode: bool
  world: World
  camera: Camera2D
  worldUI: WorldUI
  aParams, eParams: seq[MinimalParams]
  nAlly, nEnemy: int
  matchRule: MatchRule
  oldScores: array[Team, float32] = [0, 0]
  rewards: array[Team, float32] = [0, 0]


proc initEnv*(aParamsArg, eParamsArg: seq[MinimalParams], renderMode: bool): WorldEnv =
  result.matchRule = MatchRule()
  result.matchRule.maxX = maxX
  result.matchRule.maxY = maxY
  result.matchRule.maxHeight = maxHeight

  result.matchRule.heightCd = 4
  result.matchRule.scoreInterval = 5
  result.matchRule.scoreKaisuu = 3
  result.matchRule.scoreBase = 5
  result.matchRule.matchTime = 60
  result.aParams = aParamsArg
  result.eParams = eParamsArg
  result.nAlly = aParamsArg.len
  result.nEnemy = eParamsArg.len

  if renderMode:
    initWindow(width, height, "training")
    result.renderMode = true


proc reset*(self: var WorldEnv) =
  self.world = newWorld(self.matchRule, Vsize, self.aParams, self.eParams)
  self.camera = Camera2D(zoom: 1, target: Vector2(x: -100, y: -100), offset: Vector2(x: width / 2, y: height / 2))
  self.worldUI = initWorldUI(self.world, uiObs)
  self.oldScores = [0, 0]
  self.rewards = [0, 0]


proc setAction*(self: var WorldEnv, unitId, action: int) =
  let
    moveOrHeight = action mod 21
    rotateAction = action div 21
  var u = addr self.world.units[unitId]
  let curTile = self.world.map.pos2tile(u.move.pos)
  case moveOrHeight:
    of 0..5:
      let targetTile = getAdjacentTile(curTile, moveOrHeight)
      addPath(u[], self.world, targetTile)
    of 6:
      discard
    of 7..13:
      var targetTile: Vector2i
      if moveOrHeight == 13:
        targetTile = curTile
      else:
        targetTile = getAdjacentTile(curTile, moveOrHeight - 7)
      self.world.heightSystem.tryStart(u[], targetTile, true)
    of 14..20:
      var targetTile: Vector2i
      if moveOrHeight == 20:
        targetTile = curTile
      else:
        targetTile = getAdjacentTile(curTile, moveOrHeight - 14)
      self.world.heightSystem.tryStart(u[], targetTile, false)
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


# proc isDead(unitId: int): bool =
#   return worldEnv.units[unitId].isDead


proc isMovable(self: World, unitId: int, moveAction: int): bool =
  if self.units[unitId].move.movingWeight != 0:
    return false
  let
    curTile = self.map.pos2tile(self.units[unitId].move.pos)
    nextTile = getAdjacentTile(curTile, moveAction)
  return self.map.isExists(nextTile) and self.map.isMovable(curTile, nextTile)


proc isChangeable(self: World, unitId, hAct: int): bool =
  if self.units[unitId].move.movingWeight != 0:
    return false
  let team = self.units[unitId].team
  if not self.heightSystem.canStartAction(team):
    return false

  let isRaise = hAct <= 13
  var targetIdx = if isRaise: hAct - 7 else: hAct - 14
  let curTile = self.map.pos2tile(self.units[unitId].move.pos)
  let targetTile = if targetIdx == 6: curTile else: getAdjacentTile(curTile, targetIdx)
  
  return self.map.isExists(targetTile) and
      self.map.isMovable(curTile, targetTile) and
      self.map.canChangeHeight(targetTile, isRaise)


const MaskV = -1e9'f32
proc getMask*(self: WorldEnv, unitId: int): Tensor[float32] =
  let world = self.world
  if world.units[unitId].isDead:
    result = newTensorWith[float32](63, MaskV)
    result[6] = 0
    return
  result = newTensor[float32](63)
  for i in 0..5:
    if not isMovable(world, unitId, i):
      for r in 0..2:
        result[r * 21 + i] = MaskV
  for i in 7..20:
    if not isChangeable(world, unitId, i):
      for r in 0..2:
        result[r * 21 + i] = MaskV


proc fillUnitObs(u: Unit, pos: Vector2): Tensor[float32] =
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
  ].toTensor


proc getObsOfSelf(world: World, unitId: int): Tensor[float32] =
  let u = world.units[unitId]
  let isDead = u.isDead().float32
  let head = [isDead].toTensor()
  if isDead == 1.0'f32:
    return concat(head, zeros[float32](14), axis = 0)
  
  let body = fillUnitObs(u, u.move.pos / maxPosX.float32)
  return concat(head, body, axis = 0)


proc getObsAlly(world: World, selfId, targetId: int): Tensor[float32] =
  let
    sPos = world.units[selfId].move.pos
    t = world.units[targetId]
    isDead = t.isDead().float32
  let head = [isDead].toTensor()
  if isDead == 1.0'f32:
    return concat(head, zeros[float32](14), axis = 0)
    
  let body = fillUnitObs(t, (t.move.pos - sPos) / maxPosX.float32)
  return concat(head, body, axis = 0)


proc getObsEnemy(world: World, selfId, targetId: int): Tensor[float32] =
  let 
    sPos = world.units[selfId].move.pos
    t = world.units[targetId]
    isDead = t.isDead().float32
  let head = [isDead].toTensor()
  if isDead == 1.0'f32:
    return concat(head, zeros[float32](14), axis = 0)
  
  let vis = t.vision.visibleState
  var targetPos = if vis == visVisible: t.move.pos else: t.vision.lastPosition
  
  var relPos = (targetPos - sPos) / maxPosX

  var body = fillUnitObs(t, relPos)
  if vis != visVisible:
    body[2] = 0.0'f32
    body[9] = 0.0'f32
    body[10] = 0.0'f32

  return concat(head, body, axis = 0)


proc getObsHeight(world: World): Tensor[float32] =
  result = newTensor[float32](1, maxX + 1, maxY + 1)
  for y in 0..maxY:
    for x in 0..maxX:
      result[0, x, y] = world.map.getHeight(Vector2i(x: x, y: y)).float32 / maxHeight.float32


proc getObsUnitsMap(world: World, myUnitId: int): Tensor[float32] =
  # result[0]: 自分自身 (1.0)
  # result[1]: 味方 (1.0)
  # result[2]: 敵の現在地 (1.0)
  # result[3]: 敵の最終確認位置 (0.5)
  result = newTensor[float32](4, maxX + 1, maxY + 1)
  let
    myUnit = world.units[myUnitId]
    mySide = myUnit.team
  
  for u in world.units:
    let tile = world.map.pos2tile(u.move.pos)

    if u.id == myUnitId:
      result[0, tile.x, tile.y] = 1
    elif u.team == mySide:
      result[1, tile.x, tile.y] += 0.1
    else:
      if u.vision.visibleState == visVisible:
        result[2, tile.x, tile.y] += 0.1
      else:
        # 最後に確認された座標を変換
        if u.vision.lastPosition.x > -10000.0:
          let lastTile = world.map.pos2tile(u.vision.lastPosition)
          if lastTile.x in 0..maxX and lastTile.y in 0..maxY:
            result[3, lastTile.x, lastTile.y] += 0.1


proc getObsScoreMap(world: World, unitId: int): Tensor[float32] =
  # result[0]: 味方の残り回数 (正規化)
  # result[1]: 味方の残り時間 (正規化)
  # result[2]: 敵の残り回数 (正規化)
  # result[3]: 敵の残り時間 (正規化)
  let isAlly = world.units[unitId].team == Team.Ally
  result = newTensor[float32](4, maxX + 1, maxY + 1)
  let ss = world.scoreSystem
  
  let maxCount: float32 = 5
  let maxInterval: float32 = 30

  let
    myTeam = if isAlly: Team.Ally else: Team.Enemy
    oppTeam = if isAlly: Team.Enemy else: Team.Ally
  for t in ss.effTiles[myTeam]:
    if t.tile.x in 0..maxX and t.tile.y in 0..maxY:
      result[0, t.tile.x, t.tile.y] = t.leftCount.float32 / maxCount
      result[1, t.tile.x, t.tile.y] = t.leftTime / maxInterval

  for t in ss.effTiles[oppTeam]:
    if t.tile.x in 0..maxX and t.tile.y in 0..maxY:
      result[2, t.tile.x, t.tile.y] = t.leftCount.float32 / maxCount
      result[3, t.tile.x, t.tile.y] = t.leftTime / maxInterval


proc getLeftMatchTime(world: World): Tensor[float32] =
  [world.leftMatchTime].toTensor


proc getObs*(self: WorldEnv, unitId: int): tuple[map, lin: Tensor[float32]] =
  let 
    world = self.world
    u = world.units[unitId]
    isAlly = u.team == Team.Ally
  result.map = concat(getObsHeight(world), getObsUnitsMap(world, unitId), getObsScoreMap(world, unitId), axis = 0)

  
  var linParts = @[getObsOfSelf(world, unitId)]
  let 
    allyIds = if isAlly: toSeq(0..<self.nAlly) else: toSeq(self.nAlly..<self.nAlly + self.nEnemy)
    enemyIds = if isAlly: toSeq(self.nAlly..<self.nAlly + self.nEnemy) else: toSeq(0..<self.nAlly)
  
  let pad = [1.0'f32].toTensor().concat(zeros[float32](14), 0)
  var aCount = 0
  for id in allyIds:
    if id == unitId: continue
    if aCount < 6:
      linParts.add(getObsAlly(world, unitId, id))
      inc aCount
  while aCount < 6:
    linParts.add(pad); inc aCount

  var eCount = 0
  for id in enemyIds:
    if eCount < 7:
      linParts.add(getObsEnemy(world, unitId, id))
      inc eCount
  while eCount < 7:
    linParts.add(pad); inc eCount

  linParts.add(getLeftMatchTime(world))
  result.lin = concat(linParts, 0)


proc draw(self: var WorldEnv) =
  if not windowShouldClose():
    dragCamera(self.camera)
    zoomCamera(self.camera)

    beginDrawing()
    clearBackground(Brown)

    self.worldUI.draw(self.world, self.camera)

    drawFPS(1, 1)

    endDrawing()


proc step*(self: var WorldEnv) =
  self.world.update(Delta)
  
  for t in Team:
    self.rewards[t] = self.world.scoreSystem.scores[t] - self.oldScores[t]
    if self.world.heightSystem.areChanged[t].isChanged:
      self.rewards[t] += 1
    self.rewards[t] *= 0.1

    self.oldScores[t] = self.world.scoreSystem.scores[t]

  if self.renderMode:
    self.draw()


proc isTerminated*(self: WorldEnv): bool =
  return self.world.leftMatchTime <= 0


proc getReward*(self: WorldEnv, unitId: int): float32 =
  let team = self.world.units[unitId].team
  return self.rewards[team]