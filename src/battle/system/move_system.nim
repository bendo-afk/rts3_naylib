import ../unit/unit
import ../map/tilemap
import ../rules/conversion

type MoveSystem* = object
  diff2speed: Conversion
  map: TileMap


proc newMoveSystem*(diff2speed: Conversion, map: TileMap): MoveSystem =
  MoveSystem(diff2speed: diff2speed, map: map)


proc setMultiplier*(moveSys: MoveSystem, mComp: var MoveComp) =
  if mComp.path.len < 2:
    return
  let
    t1 = moveSys.map.pos2tile(mComp.path[0])
    t2 = moveSys.map.pos2tile(mComp.path[1])
    h1 = moveSys.map.get_height(t1)
    h2 = moveSys.map.get_height(t2)
    diff = h2 - h1
  mComp.multiplier = moveSys.diff2speed.calc(diff.float32)
  

proc update*(moveSys: MoveSystem, units: var seq[Unit], delta: float32) =
  for u in units.mitems:
    if u.isDead or u.heightAction.isChanging:
      continue
    u.move.movePos2Pos(delta)
    if u.move.movingWeight == 1:
      u.move.movingWeight = 0
      u.move.path.delete(0)
      setMultiplier(moveSys, u.move)
