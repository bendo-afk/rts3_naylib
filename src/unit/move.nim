import raylib, raymath


type MoveComp* = object
  speed: float
  movingWeight: float


proc newMoveComp*(speed: float): MoveComp =
  MoveComp(speed: speed, movingWeight: 0)


proc movePos2Pos*(moveComp: var MoveComp, fromPos, toPos: Vector2, multiplier, delta: float): (Vector2, bool)  =
  let speed = moveComp.speed * multiplier
  moveComp.movingWeight = max(moveComp.movingWeight + speed * delta, 0)
  let newPos = lerp(fromPos, toPos, moveComp.movingWeight)

  if moveComp.movingWeight == 1:
    moveComp.movingWeight = 0
    return (newPos, true)
  
  return (newPos, false)
