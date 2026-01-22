import raylib
import height_action, hp, move, vision


type Unit* = object
  heightAction: HeightActionComp
  hp: HpComp
  move*: MoveComp
  vision: VisionComp
  isSelected*: bool


proc newUnit*(maxTimer: float, maxHp: int, speed, height: float, pos: Vector2): Unit =
  Unit(heightAction: newHeightActionComp(maxTimer), hp: newHpComp(maxHp), move: newMoveComp(speed, pos), vision: newVisionComp(height))