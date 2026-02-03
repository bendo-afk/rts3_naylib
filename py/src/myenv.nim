import nimpy
import raylib, raymath
import battle/world
import battle/map/[hex_math, tilemap]
import battle/unit/unit
import battle/system/height_system

var worldEnv: World

# proc getMapObs(unitId: int)

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

proc getObs(unitId: int) =
  