type HeightActionComp* = object
  isChanging: bool
  maxTimer: float
  leftTimer: float


proc newHeightActionComp*(maxTimer, leftTimer: float): HeightActionComp =
  HeightActionComp(isChanging: false, maxTimer: maxTimer, leftTimer: leftTimer)


proc physics*(heightActionComp: var HeightActionComp, delta: float) =
  if heightActionComp.isChanging:
    heightActionComp.leftTimer -= delta