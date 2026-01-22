type VisibleState* = enum
  visNot, visHalf, visVisible

type VisionComp* = object
  height*: float
  visibleState*: VisibleState


proc newVisionComp*(height: float): VisionComp =
  VisionComp(height: height, visibleState: visNot)