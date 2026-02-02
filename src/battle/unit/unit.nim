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
        maxReloadTime, leftReloadTime, turretAngle: float,
        maxTimer: float, maxHp: int, speed: int, height: float, pos: Vector2, id: int): Unit =
  let
    attack = newAttackComp(damage, traverseSpeed, angleMargin,
        maxReloadTime, leftReloadTime, turretAngle)
    heightAction = newHeightActionComp(maxTimer)
    hp = newHpComp(maxHp)
    move = newMoveComp(speed, pos)
    vision = newVisionComp(height)
  Unit(attack: attack, heightAction: heightAction, hp: hp, move: move, vision: vision, id: id)

