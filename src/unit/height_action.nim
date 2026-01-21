type HeightActionComp* = object
  isChanging: bool
  maxCd: float
  leftCd: float


proc newHeightActionComp*(maxCd: float): HeightActionComp =
  HeightActionComp(isChanging: false, maxCd: maxCd, leftCd: 0)


proc physics*(heightActionComp: var HeightActionComp, delta: float) =
  if heightActionComp.isChanging:
    heightActionComp.leftCd -= delta