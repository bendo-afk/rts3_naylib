import ../unit/move
import ../map/tilemap
import ../rules/conversion

type MoveSystem* = object
  diff2speed: Conversion
  mComps: seq[MoveComp]
  map: TileMap


proc newMoveSystem*(diff2speed: Conversion, mComps: seq[MoveComp], map: TileMap): MoveSystem =
  MoveSystem(diff2speed: diff2speed, mComps: mComps, map: map)


proc setMultiplier*(moveSys: MoveSystem, mComp: var MoveComp) =
  if mComp.path.len < 2:
    return
  let
    t1 = moveSys.map.pos2tile(mComp.path[0])
    t2 = moveSys.map.pos2tile(mComp.path[1])
    h1 = moveSys.map.get_height(t1)
    h2 = moveSys.map.get_height(t2)
    diff = h2 - h1
  mComp.multiplier = moveSys.diff2speed.calc(diff.float)
  

proc update*(moveSys: var MoveSystem, delta: float32) =
  for m in moveSys.mComps.mitems:
    m.movePos2Pos(delta)
    if m.movingWeight == 1:
      m.path.delete(0)
      m.movingWeight = 0
      if m.path.len >= 2:
        setMultiplier(moveSys, m)


