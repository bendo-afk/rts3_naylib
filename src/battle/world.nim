import sequtils
import raylib

import rules/[match_rule as mr, conversion]
import map/tilemap
import unit/unit
import system/move_system
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

  moveSystem: MoveSystem

  dragBox*: DragBox



proc newUnit(mr: MatchRule, params: MinimalParams): Unit =
  let
    traverseSpeed = mr.speed2traverse.calc(params.speed.float)
    angleMargin = mr.angleMargin.float
    maxReloadTime = mr.damage2reload.calc(params.damage.float)
    leftReloadTime = maxReloadTime
    turretAngle = 0.float
    maxTimer = mr.heightActionTimer.float
    leftTimer = 0.float
  newUnit(params.damage, traverseSpeed, angleMargin,
        maxReloadTime, leftReloadTime, turretAngle,
        maxTimer, leftTimer, params.maxHp, params.speed, params.height, params.pos)


proc setupTeam(mr: MatchRule, teamSeq: var seq[Unit], unitsParams: seq[MinimalParams]) =
  for p in unitsParams:
    teamSeq.add(newUnit(mr, p))


proc newWorld*(matchRule: MatchRule, vsize: float): World =
  let map = newTileMap(vsize, matchRule.maxX, matchRule.maxY, matchRule.maxHeight)
  
  var aUnits: seq[Unit]
  var aParams: seq[MinimalParams]
  aParams = @[(1, 1, 10, 1, 0, map.tile2pos(Vector2i(x: 0, y: 0)))]
  setupTeam(matchRule, aUnits, aParams)

  aParams[0].pos = map.tile2pos(Vector2i(x: matchRule.maxX, y: matchRule.maxY))
  var eUnits: seq[Unit]
  var eParams = aParams
  setupTeam(matchRule, eUnits, eParams)


  let mComps = aUnits.mapIt(it.move)
  let moveSys = newMoveSystem(matchRule.diff2speed, mComps, map)

  let dragBox = newDragBox()
  return World(matchRule: matchRule, map: map, aUnits: aUnits, eUnits: eUnits, moveSystem: moveSys, dragBox: dragBox)



proc update*(world: var World) =
  # deltaってどこで取得すべきなんだ？
  world.moveSystem.update(getFrameTime())
  discard


proc draw*(world: World, camera: Camera2D) =
  mode2D(camera):
    world.map.draw_map()
    for a in world.aUnits:
      drawCircle(a.move.pos, unitSize.float32, RayWhite)
    
    for e in world.eUnits:
      # if e.vision.visibleState == visVisible:
      drawCircle(e.move.pos, unitSize.float32, Red)
    
    if world.dragBox.dragging:
      drawRectangle(world.dragBox.rect, boxColor)
      drawRectangleLines(world.dragBox.rect, 2 / camera.zoom,lineColor)
    


proc setPath*(world: var World, pos: Vector2) =
  let toTile = world.map.pos2tile(pos)
  if not isExists(world.map, toTile):
    return
  for a in world.aUnits.mitems:
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