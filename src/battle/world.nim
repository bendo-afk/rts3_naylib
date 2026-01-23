import algorithm, sequtils
import raylib, raymath

import rules/match_rule as mr
import map/tilemap
import unit/unit
import system/[attack_system, height_system, move_system, vision_system, score_system]
import ../utils
import ../control


type MinimalParams = tuple
  damage: int
  maxTimer: float
  maxHp: int
  speed: int
  height: float
  pos: Vector2


var boxColor = Color(r: 0, g: 178, b: 255, a: 76)
var lineColor = Color(r: 0, g: 127, b: 255, a: 153)


var unitSize = 10


type World* = object
  matchRule: MatchRule

  map: TileMap
  aUnits: seq[Unit]
  eUnits: seq[Unit]

  attackSystem: AttackSystem
  heightSystem: HeightSystem
  moveSystem: MoveSystem
  scoreSystem: ScoreSystem
  visionSystem: VisionSystem

  dragBox*: DragBox



proc newUnit(mr: MatchRule, params: MinimalParams): Unit =
  let
    traverseSpeed = mr.speed2traverse.calc(params.speed.float)
    angleMargin = mr.angleMargin.float
    maxReloadTime = mr.damage2reload.calc(params.damage.float)
    leftReloadTime = maxReloadTime
    turretAngle = 0.float
    maxTimer = mr.heightActionTimer.float
  newUnit(params.damage, traverseSpeed, angleMargin,
        maxReloadTime, leftReloadTime, turretAngle,
        maxTimer, params.maxHp, params.speed, params.height, params.pos)


proc setupTeam(mr: MatchRule, teamSeq: var seq[Unit], unitsParams: seq[MinimalParams]) =
  for p in unitsParams:
    teamSeq.add(newUnit(mr, p))


proc newWorld*(matchRule: MatchRule, vsize: float): World =
  let map = newTileMap(vsize, matchRule.maxX, matchRule.maxY, matchRule.maxHeight)
  
  var aUnits: seq[Unit]
  var aParams: seq[MinimalParams]
  aParams.setLen(7)
  var param: MinimalParams = (1, 1.float, 10, 1, 0.float, map.tile2pos(Vector2i(x: 0, y: 0)))
  aParams.fill(param)
  setupTeam(matchRule, aUnits, aParams)

  param.pos = map.tile2pos(Vector2i(x: matchRule.maxX, y: matchRule.maxY))
  aParams.fill(param)
  var eUnits: seq[Unit]
  var eParams = aParams
  setupTeam(matchRule, eUnits, eParams)


  let units = aUnits.concat(eUnits)
  let attackSys = newAttackSystem(units)
  let moveSys = newMoveSystem(matchRule.diff2speed, units, map)
  let visionSys = newVisionSystem(map, matchRule.lMargin, matchRule.sMargin, aUnits, eUnits)
  let heightSys = newHeightSystem(map, matchRule.heightCd)
  let scoreSys = newScoreSystem(matchRule.scoreInterval, matchRule.scoreKaisuu, matchRule.scoreBase, matchRule.dist2penalty)

  let dragBox = newDragBox()

  return World(matchRule: matchRule, map: map, aUnits: aUnits, eUnits: eUnits, heightSystem: heightSys, moveSystem: moveSys, visionSystem: visionSys, dragBox: dragBox, attackSystem: attackSys, scoreSystem: scoreSys)



proc update*(world: var World, delta: float) =
  # deltaってどこで取得すべきなんだ？
  world.attackSystem.update(delta)
  world.heightSystem.update(delta)
  world.moveSystem.update(delta)
  world.visionSystem.update()
  world.scoreSystem.update(delta)

  let areTilesChanged = world.heightSystem.areChanged
  for i, itc in areTilesChanged:
    if itc.isChanged:
      world.scoreSystem.onTileChanged(itc.tile, i == 0, getTime())

  discard


proc draw*(world: World, camera: Camera2D) =
  mode2D(camera):
    world.map.draw_map()
    for a in world.aUnits:
      drawCircle(a.move.pos, unitSize.float32, RayWhite)
      drawLine(a.move.pos, a.move.pos + Vector2(x: 1000 * cos(a.attack.turretAngle), y: 1000 * sin(a.attack.turretAngle)), 2, RayWhite)
    
    for e in world.eUnits:
      if e.vision.visibleState == visVisible:
        drawCircle(e.move.pos, unitSize.float32, Red)
    
    if world.dragBox.dragging:
      drawRectangle(world.dragBox.rect, boxColor)
      drawRectangleLines(world.dragBox.rect, 2 / camera.zoom,lineColor)
    


proc setPath*(world: World, pos: Vector2) =
  let toTile = world.map.pos2tile(pos)
  if not isExists(world.map, toTile):
    return
  for a in world.aUnits:
    if not a.isSelected:
      continue
    if a.move.movingWeight != 0:
      let
        addedPath2i = world.map.calcPath(world.map.pos2tile(a.move.path[1]), toTile)
        addedPath2 = addedPath2i.mapIt(world.map.tile2pos(it))
      a.move.path.setLen(1)
      a.move.path.add(addedPath2)
    else:
      let
        fromTile = world.map.pos2tile(a.move.pos)
        addedPath2i = world.map.calcPath(fromTile, toTile)
        addedPath2 = addedPath2i.mapIt(world.map.tile2pos(it))
      a.move.path = addedPath2
      world.moveSystem.setMultiplier(a.move)


proc selectByBox*(world: var World, rect: Rectangle) =
  for a in world.aUnits.mitems:
    if a.move.pos.x >= rect.x and a.move.pos.x <= rect.x + rect.width and
        a.move.pos.y >= rect.y and a.move.pos.y <= rect.y + rect.height:
          a.isSelected = true

proc deselect*(world: var World) =
  for a in world.aUnits.mitems:
    a.isSelected = false


proc setTargetPos*(self: World, pos: Vector2) =
  for a in self.aUnits:
    if a.isSelected:
      a.attack.targetPos = pos


proc changeHeight*(self: var World, pos: Vector2, isRaise: bool) =
  let tile = self.map.pos2tile(pos)
  for a in self.aUnits:
    if not a.isSelected or a.move.movingWeight != 0:
      continue
    self.heightSystem.tryStart(a, true, tile, isRaise)