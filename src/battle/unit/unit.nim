import raylib
import height_action, hp, move, vision, attack
export height_action, hp, move, vision, attack


type Unit* = ref object
  attack*: AttackComp
  heightAction*: HeightActionComp
  hp*: HpComp
  move*: MoveComp
  vision*: VisionComp
  isSelected*: bool
  visibleEnemies*: seq[Unit]


proc newUnit*(damage: int, traverseSpeed, angleMargin,
        maxReloadTime, leftReloadTime, turretAngle: float,
        maxTimer: float, maxHp: int, speed: int, height: float, pos: Vector2): Unit =
  let
    attack = newAttackComp(damage, traverseSpeed, angleMargin,
        maxReloadTime, leftReloadTime, turretAngle)
    heightAction = newHeightActionComp(maxTimer)
    hp = newHpComp(maxHp)
    move = newMoveComp(speed, pos)
    vision = newVisionComp(height)
  Unit(attack: attack, heightAction: heightAction, hp: hp, move: move, vision: vision)