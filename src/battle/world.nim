import sequtils
import raylib, raymath

import rules/match_rule as mr
import map/tilemap
import unit/unit
import system/[attack_system, height_system, move_system, vision_system, score_system]
import ../utils
import ../control


type MinimalParams* = tuple
  damage: int
  maxTimer: float
  maxHp: int
  speed: int
  height: float


type World* = object
  matchRule: MatchRule

  map*: TileMap
  units*: seq[Unit]

  attackSystem: AttackSystem
  heightSystem*: HeightSystem
  moveSystem: MoveSystem
  scoreSystem*: ScoreSystem
  visionSystem: VisionSystem

  dragBox*: DragBox

  leftMatchTime*: float



proc newUnit(mr: MatchRule, params: MinimalParams, pos: Vector2): Unit =
  let
    traverseSpeed = mr.speed2traverse.calc(params.speed.float)
    angleMargin = mr.angleMargin.float
    maxReloadTime = mr.damage2reload.calc(params.damage.float)
    leftReloadTime = maxReloadTime
    turretAngle = 0.float
    maxTimer = mr.heightActionTimer.float
  result = newUnit(params.damage, traverseSpeed, angleMargin,
        maxReloadTime, leftReloadTime, turretAngle,
        maxTimer, params.maxHp, params.speed, params.height, pos)


proc newWorld*(matchRule: MatchRule, mapVsize: float, aParams, eParams: seq[MinimalParams]): World =
  result.matchRule = matchRule
  result.map = newTileMap(mapVsize, matchRule.maxX, matchRule.maxY, matchRule.maxHeight)

  result.units = newseq[Unit]()
  let aPos = result.map.tile2pos(Vector2i(x: 0, y: 0))
  for p in aParams:
    var u = newUnit(matchRule, p, aPos)
    u.team = Team.Ally
    u.id = result.units.len
    result.units.add(u)

  let ePos = result.map.tile2pos(Vector2i(x: matchRule.maxX, y: matchRule.maxY))
  for p in eParams:
    var u = newUnit(matchRule, p, ePos)
    u.team = Team.Enemy
    u.id = result.units.len
    result.units.add(u)

  result.attackSystem = newAttackSystem()
  result.moveSystem = newMoveSystem(matchRule.diff2speed, result.map)
  result.visionSystem = newVisionSystem(result.map, matchRule.lMargin, matchRule.sMargin)
  result.heightSystem = newHeightSystem(result.map, matchRule.heightCd)
  result.scoreSystem = newScoreSystem(matchRule.scoreInterval, matchRule.scoreKaisuu, matchRule.scoreBase, matchRule.dist2penalty)
  result.dragBox = newDragBox()
  result.leftMatchTime = matchRule.matchTime

  

proc update*(self: var World, delta: float) =
  # deltaってどこで取得すべきなんだ？
  self.attackSystem.update(self.units, delta)
  self.heightSystem.update(self.units, delta)
  self.moveSystem.update(self.units, delta)
  self.visionSystem.update(self.units)
  self.scoreSystem.update(delta)

  for u in self.units.mitems:
    if u.lifeState == lsDying:
      u.lifeState = lsDead
      u.isSelected = false

  let areTilesChanged = self.heightSystem.areChanged
  for i, itc in areTilesChanged:
    if itc.isChanged:
      self.scoreSystem.onTileChanged(itc.tile, i == 0, getTime())
  
  self.leftMatchTime -= delta
  if self.leftMatchTime <= 0:
    discard


proc addPath*(u: var Unit, world: World, toTile: Vector2i) =
    if u.move.movingWeight != 0:
      let
        addedPath2i = world.map.calcPath(world.map.pos2tile(u.move.path[1]), toTile)
        addedPath2 = addedPath2i.mapIt(world.map.tile2pos(it))
      u.move.path.setLen(1)
      u.move.path.add(addedPath2)
    else:
      let
        fromTile = world.map.pos2tile(u.move.pos)
        addedPath2i = world.map.calcPath(fromTile, toTile)
        addedPath2 = addedPath2i.mapIt(world.map.tile2pos(it))
      u.move.path = addedPath2
      world.moveSystem.setMultiplier(u.move)


proc setPath*(world: var World, pos: Vector2) =
  let toTile = world.map.pos2tile(pos)
  if not isExists(world.map, toTile):
    return
  for a in world.units.mitems:
    if a.team != Ally: continue
    if not a.isSelected:
      continue
    addPath(a, world, toTile)


proc selectByBox*(world: var World, rect: Rectangle) =
  for a in world.units.mitems:
    if a.team != Ally or a.isDead: continue
    if a.move.pos.x >= rect.x and a.move.pos.x <= rect.x + rect.width and
        a.move.pos.y >= rect.y and a.move.pos.y <= rect.y + rect.height:
          a.isSelected = true

proc deselect*(world: var World) =
  for a in world.units.mitems:
    if a.team != Ally: continue
    a.isSelected = false


proc setTargetPos*(self: var World, pos: Vector2) =
  for a in self.units.mitems:
    if a.team != Ally: continue
    if a.isSelected:
      a.attack.targetPos = pos


proc changeHeight*(self: var World, pos: Vector2, isRaise: bool) =
  let tile = self.map.pos2tile(pos)
  for a in self.units.mitems:
    if a.team != Ally: continue
    if not a.isSelected or a.move.movingWeight != 0:
      continue
    self.heightSystem.tryStart(a, true, tile, isRaise)
