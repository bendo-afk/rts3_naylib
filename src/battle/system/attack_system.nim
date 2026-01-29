import raymath
import ../unit/unit
import ../../utils

type AttackSystem* = object
  units: seq[Unit]

proc newAttackSystem*(units: seq[Unit]): AttackSystem =
  AttackSystem(units: units)

proc update*(self: AttackSystem, delta: float) =
  for u in self.units:
    if u.attack.leftReloadTime == 0:
      var minAngleDiff = u.attack.angleMargin
      var targetEnemy: Unit = nil
      for v in u.visibleEnemies:
        if v.hp.hp <= 0:
          continue

        let diffVec = v.move.pos - u.move.pos
        if diffVec.x == 0 and diffVec.y == 0:
          targetEnemy = v
          break

        let targetAngle = diffVec.angle()
        let angleDiff = abs(angleDifference(targetAngle, u.attack.turretAngle))

        if angleDiff < minAngleDiff:
          minAngleDiff = angleDiff
          targetEnemy = v
      
      if targetEnemy != nil:
        targetEnemy.hp.takeDamage(u.attack.damage)
        u.attack.leftReloadTime = u.attack.maxReloadTime
    
    let relTargetPos = u.attack.targetPos - u.move.pos
    u.attack.rotateTurret(relTargetPos, delta)

    u.attack.leftReloadTime = max(u.attack.leftReloadTime - delta, 0)