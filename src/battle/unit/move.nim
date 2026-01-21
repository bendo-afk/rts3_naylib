import raylib, raymath


type MoveComp* = ref object
  speed: float
  pos*: Vector2
  movingWeight*: float
  path*: seq[Vector2]
  multiplier*: float


proc newMoveComp*(speed: float, pos: Vector2): MoveComp =
  MoveComp(speed: speed, movingWeight: 0, pos: pos)


proc movePos2Pos*(moveComp: var MoveComp, delta: float32) =
  if moveComp.path.len < 2:
    return
  let speed = moveComp.speed * moveComp.multiplier
  moveComp.movingWeight = min(1, moveComp.movingWeight + speed * delta)
  let
    fromPos = moveComp.path[0]
    toPos = moveComp.path[1]
  moveComp.pos = lerp(fromPos, toPos, moveComp.movingWeight)