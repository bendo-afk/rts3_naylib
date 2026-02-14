import arraymancer

let (N, DIn, H, DOut) = (64, 1000, 100, 10)

let ctx = newContext Tensor[float32]

let
  x = ctx.variable(randomTensor[float32](N, DIn, 1'f32))
  y = randomTensor[float32](N, DOut, 1'f32)


network TwoLayerNet:
  layers:
    fc1: Linear(DIn, H)
    fc2: Linear(H, DOut)
  forward x:
    x.fc1.relu.fc2


let
  model = ctx.init(TwoLayerNet)
  optim = model.optimizer(SGD, learning_rate = 1e-4'f32)


for t in 0..<500:
  let
    yPred = model.forward(x)
    loss = yPred.mse_loss(y)
  echo t, ":", loss.value[0]

  loss.backprop()
  optim.update()