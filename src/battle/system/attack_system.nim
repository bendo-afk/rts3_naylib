import raymath
import ../unit/unit
import ../../utils

type AttackSystem* = object

proc newAttackSystem*(): AttackSystem =
  # AttackSystem(units: units)
  AttackSystem()

proc update*(self: AttackSystem, units: var seq[Unit], delta: float32) =
  for u in units.mitems:
    if u.isDead(): continue

    if u.attack.leftReloadTime == 0:
      var minAngleDiff = u.attack.angleMargin
      var targetEnemyId: UnitId = -1
      for idx in u.visibleEnemyIds:
        var v = addr units[idx]
        if v.hp.hp <= 0:
          continue

        let diffVec = v.move.pos - u.move.pos
        if diffVec.x == 0 and diffVec.y == 0:
          targetEnemyId = v.id
          break

        let targetAngle: float32 = diffVec.angle()
        let angleDiff: float32 = abs(angleDifference(targetAngle, u.attack.turretAngle))

        if angleDiff < minAngleDiff:
          minAngleDiff = angleDiff
          targetEnemyId = v.id
      
      if targetEnemyId != -1:
        var v = addr units[targetEnemyId]
        v.hp.takeDamage(u.attack.damage)
        if v.hp.hp <= 0:
          v.lifeState = lsDying
        u.attack.leftReloadTime = u.attack.maxReloadTime
    
    let relTargetPos = u.attack.targetPos - u.move.pos
    u.attack.rotateTurret(relTargetPos, delta)

    u.attack.leftReloadTime = max(u.attack.leftReloadTime - delta, 0)