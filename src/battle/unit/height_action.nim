type HeightActionComp* = object
  isChanging*: bool
  maxTimer*: float32
  leftTimer*: float32


proc newHeightActionComp*(maxTimer: float32): HeightActionComp =
  HeightActionComp(isChanging: false, maxTimer: maxTimer, leftTimer: maxTimer)


proc update*(heightActionComp: var HeightActionComp, delta: float32) =
  if heightActionComp.isChanging:
    heightActionComp.leftTimer -= delta


proc reset*(self: var HeightActionComp) =
  self.isChanging = false
  self.leftTimer = self.maxTimer
