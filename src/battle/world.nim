import sequtils
import raylib

import rules/match_rule as mr
import map/tilemap
import unit/unit
import system/move_system
import ../utils


var unitSize = 10

type World* = object
  matchRule: MatchRule

  map: TileMap
  aUnits: seq[Unit]
  eUnits: seq[Unit]

  moveSystem: MoveSystem


proc newWorld*(matchRule: MatchRule, vsize: float): World =
  let map = newTileMap(vsize, matchRule.maxX, matchRule.maxY, matchRule.maxHeight)
  var aUnits = @[newUnit(1, 10, 1, 0, map.tile2pos(Vector2i(x: 0, y: 0)))]
  # Initialize move system with units' MoveComp so map is set inside MoveSystem
  let mComps = aUnits.mapIt(it.move)
  let moveSys = newMoveSystem(matchRule.diff2speed, mComps, map)
  return World(matchRule: matchRule, map: map, aUnits: aUnits, moveSystem: moveSys)



proc update*(world: var World) =
  # deltaってどこで取得すべきなんだ？
  world.moveSystem.update(getFrameTime())
  discard


proc draw*(world: World, camera: Camera2D) =
  mode2D(camera):
    world.map.draw_map()
    for a in world.aUnits:
      drawCircle(a.move.pos, unitSize.float32, RayWhite)

proc setPath*(world: var World, pos: Vector2) =
  let toTile = world.map.pos2tile(pos)
  if not isExists(world.map, toTile):
    return
  for a in world.aUnits.mitems:
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