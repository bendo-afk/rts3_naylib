import raylib

type VisibleState* = enum
  visNot, visHalf, visVisible

type VisionComp* = object
  height*: float32
  visibleState*: VisibleState
  lastPosition*: Vector2


proc newVisionComp*(height: float32): VisionComp =
  result.height = height
  result.visibleState = visNot
  result.lastPosition = Vector2(x: -Inf, y: -Inf)