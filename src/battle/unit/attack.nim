type AttackComp* = object
  damage: int
  traverseSpeed: float
  angleMargin: float
  maxReloadTime: float
  leftReloadTime: float
  turretAngle: float


proc newAttackComp*(damage: int, traverseSpeed, angleMargin, maxReloadTime, leftReloadTime, turretAngle: float): AttackComp =
  AttackComp(damage: damage, traverseSpeed: traverseSpeed, angleMargin: angleMargin, maxReloadTime: maxReloadTime, leftReloadTime: leftReloadTime, turretAngle: turretAngle)