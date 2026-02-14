import arraymancer

const vecD = 7 * 15 * 2 + 1


network MyPPONet:
  layers:
    cv1: Conv2D(@[8, 20, 20], 8, (3, 3))
    fl: Flatten(cv1.outShape)
    fc1: Linear(fl.outShape[0] + vecD, 256)
    fc2: Linear(256, 256)
    actionHead: Linear(256, 24 * 7)
    valueHead: Linear(256, 1)
  forward vecIn, mapIn:
    let
      mapFlat = mapIn.cv1.relu.fl
      x = stack(mapFlat, vecIn, axis=1).flatten
      h = x.fc1.relu.fc2.relu
    (h.actionHead, h.valueHead)


let
  ctx = newContext Tensor[float32]
  model = ctx.init(MyPPONet)
  optim = model.optimizer(Adam, learning_rate = 1e-4'f32)


let batchSize = 70000

var trj: seq[tuple[vecObs: array[vecD, float32], mapObs: array[8, array[20, array[20, float32]]], action: int, reward: float32]]
trj.setLen(batchSize)
var memIdx = 0

let epochs = 10


for e in 0..<epochs:
  while true:
    let (vecObs, mapObs) = env.getObs()
    let action = model.forward(vecObs, mapObs)[0]
    env.step(action)
    let reward = env.getReward()
    trj[memIdx] = (vecObs, mapObs, action, reward)
    inc memIdx
    if memIdx == batchSize:
      memIdx = 0
      break
  
  