import height_action, hp, move, vision


type Unit* = object
  heightAction: HeightActionComp
  hp: HpComp
  move: MoveComp
  vision: VisionComp

proc newUnit*(maxCd: float, maxHp: int, speed, height: float): Unit =
  Unit(heightAction: newHeightActionComp(maxCd), hp: newHpComp(maxHp), move: newMoveComp(speed), vision: newVisionComp(height))