type VisibleState = enum
  vsNot, vsHalf, vsVisible

type VisionComp* = object
  height: float
  visibleState: VisibleState


proc newVisionComp*(height: float): VisionComp =
  VisionComp(height: height, visibleState: vsNot)