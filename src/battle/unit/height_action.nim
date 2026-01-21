type HeightActionComp* = object
  isChanging: bool
  maxTimer: float
  leftTimer: float


proc newHeightActionComp*(maxTimer: float): HeightActionComp =
  HeightActionComp(isChanging: false, maxTimer: maxTimer, leftTimer: 0)


proc physics*(heightActionComp: var HeightActionComp, delta: float) =
  if heightActionComp.isChanging:
    heightActionComp.leftTimer -= delta