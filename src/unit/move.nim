import raylib, raymath


type MoveComp* = object
  pos*: Vector2
  speed: float
  movingWeight: float


proc newMoveComp*(speed: float): MoveComp =
  MoveComp(speed: speed, movingWeight: 0)


proc movePos2Pos*(moveComp: var MoveComp, fromPos, toPos: Vector2, multiplier, delta: float) =
  let speed = moveComp.speed * multiplier
  moveComp.movingWeight = max(moveComp.movingWeight + speed * delta, 0)
  moveComp.pos = lerp(fromPos, toPos, moveComp.movingWeight)
