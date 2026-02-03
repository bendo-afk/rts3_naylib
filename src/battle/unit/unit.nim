import raylib
import height_action, hp, move, vision, attack
export height_action, hp, move, vision, attack

type
  LifeState* = enum
    lsAlive, lsDying, lsDead
  Team* {.pure.} = enum
    Ally, Enemy
  UnitId* = int

type Unit* = object
  id*: UnitId
  attack*: AttackComp
  heightAction*: HeightActionComp
  hp*: HpComp
  move*: MoveComp
  vision*: VisionComp
  isSelected*: bool
  visibleEnemyIds*: seq[UnitId]
  lifeState*: LifeState = lsAlive
  team*: Team

proc newUnit*(damage: int, traverseSpeed, angleMargin,
        maxReloadTime, leftReloadTime, turretAngle: float32,
        maxTimer: float32, maxHp: int, speed: int, height: float32, pos: Vector2): Unit =
  result.attack = newAttackComp(damage, traverseSpeed, angleMargin,
        maxReloadTime, leftReloadTime, turretAngle)
  result.heightAction = newHeightActionComp(maxTimer)
  result.hp = newHpComp(maxHp)
  result.move = newMoveComp(speed, pos)
  result.vision = newVisionComp(height)
  

proc isDead*(self: Unit): bool =
  return self.lifeState == lsDead