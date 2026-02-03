import ../src/battle/world
import ../src/battle/map/[hex_math, tilemap]
import ../src/battle/unit/unit

var worldEnv: World

# proc getMapObs(unitId: int)

proc setAction(unitId: int, isAlly: bool, moveOrHeight: int, angle: float) {.export.} =
  var u = worldEnv.units[unitId]
  let curTile = worldEnv.map.pos2tile(u.move.pos)
  case moveOrHeight:
    of 0..5:
      
    of 6:
      discard
  worldEnv.heightSystem.tryStart(u, isAlly, )