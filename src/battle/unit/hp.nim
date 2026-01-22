type HpComp* = object
  maxHp: int
  hp*: int


proc newHpComp*(maxHp: int): HpComp =
  HpComp(maxHp: maxHp, hp: maxHp)


proc takeDamage*(hpComp: var HPComp, damage: int) =
  hpComp.hp = max(0, hpComp.hp - damage)
