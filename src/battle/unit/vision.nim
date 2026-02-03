type VisibleState* = enum
  visNot, visHalf, visVisible

type VisionComp* = object
  height*: float32
  visibleState*: VisibleState


proc newVisionComp*(height: float32): VisionComp =
  VisionComp(height: height, visibleState: visNot)