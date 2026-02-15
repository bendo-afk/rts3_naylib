import os, algorithm, times, sequtils, random, tables, strutils
import arraymancer
import notsac
import myenv

const linearStateSize = 7 * 15 * 2 + 1
const ConvCh = 9
const ConvW = 20
const ConvH = 20
const ActionSize = 21 * 3

randomize()

network MyQNet:
  layers:
    cv1: Conv2D(@[ConvCh, ConvW, ConvH], ConvCh, (3, 3))
    fl: Flatten(cv1.outShape)
    fcMap: Linear(fl.outShape[0], 64)
    fcLin: Linear(linearStateSize, 64)
    fc2: Linear(64, 64)
    fc3: Linear(64, 21 * 3)
  forward c, l:
    let
      xMap = c.cv1.relu.fl.fcMap.relu
      xLin = l.fcLin.relu
      combined = xMap + xLin
    return combined.fc2.relu.fc3


proc save*(network: MyQNet[float32], logAlpha: float32, path: string) =
  createDir(path)
  writeFile(path / "log_alpha.txt", $logAlpha)
  network.cv1.weight.value.write_npy(joinPath(path, "cv1w.npy"))
  network.cv1.bias.value.write_npy(joinPath(path, "cv1b.npy"))
  network.fcMap.weight.value.write_npy(joinPath(path, "fcmw.npy"))
  network.fcMap.bias.value.write_npy(joinPath(path, "fcmb.npy"))
  network.fcLin.weight.value.write_npy(joinPath(path, "fclw.npy"))
  network.fcLin.bias.value.write_npy(joinPath(path, "fclb.npy"))
  network.fc2.weight.value.write_npy(joinPath(path, "fc2w.npy"))
  network.fc2.bias.value.write_npy(joinPath(path, "fc2b.npy"))
  network.fc3.weight.value.write_npy(joinPath(path, "fc3w.npy"))
  network.fc3.bias.value.write_npy(joinPath(path, "fc3b.npy"))


proc load*(ctx: Context[Tensor[float32]], path: string): (MyQNet[float32], float32) =
  result[1] = readFile(path / "log_alpha.txt").parseFloat.float32
  result[0] = ctx.init(MyQNet)

  result[0].cv1.weight = ctx.variable(read_npy[float32](joinPath(path, "cv1w.npy")), requires_grad = true)
  result[0].cv1.bias = ctx.variable(read_npy[float32](joinPath(path, "cv1b.npy")), requires_grad = true)
  result[0].fcMap.weight = ctx.variable(read_npy[float32](joinPath(path, "fcmw.npy")), requires_grad = true)
  result[0].fcMap.bias = ctx.variable(read_npy[float32](joinPath(path, "fcmb.npy")), requires_grad = true)
  result[0].fcLin.weight = ctx.variable(read_npy[float32](joinPath(path, "fclw.npy")), requires_grad = true)
  result[0].fcLin.bias = ctx.variable(read_npy[float32](joinPath(path, "fclb.npy")), requires_grad = true)
  result[0].fc2.weight = ctx.variable(read_npy[float32](joinPath(path, "fc2w.npy")), requires_grad = true)
  result[0].fc2.bias = ctx.variable(read_npy[float32](joinPath(path, "fc2b.npy")), requires_grad = true)
  result[0].fc3.weight = ctx.variable(read_npy[float32](joinPath(path, "fc3w.npy")), requires_grad = true)
  result[0].fc3.bias = ctx.variable(read_npy[float32](joinPath(path, "fc3b.npy")), requires_grad = true)


proc loadLatestModel*(agent: var NoTSACAgent, dir: string) =
  let dirs = toSeq(walkDir(dir))
  if dirs.len == 0:
    echo "No models found"
    return

  let sortedDirs = dirs.sorted()

  let latest = sortedDirs[^1]
  echo "Loading latest: ", latest

  (agent.qnet, agent.logAlpha.value[0]) = load(agent.ctx, latest[1])
  agent.alpha = agent.logAlpha.value[0].exp


proc loadRandomModel*(agent: var NoTSACAgent, dir: string) =
  let dirs = toSeq(walkDir(dir))
  if dirs.len == 0:
    echo "No models found"
    return

  let choice = dirs[rand(dirs.len - 1)]
  echo "Loading random: ", choice
  agent.qnet = load(agent.ctx, choice[1])

let
  Gamma* = 0.98'f32
  Lr = 0.0005'f32
  Epsilon = 0.3
  BufferSize = 10000
  BatchSize = 32
  Reg = 0.1'f32


proc train(nEpisodes, maxEpiLen, saveInterval: int, modelDir: string) =
  var aParam = (2, 2'f32, 10, 1, 0'f32)
  var aParams = @[aParam, aParam]
  var eParams = aParams
  var env = initEnv(aParams, eParams, true)

  var trainAgent = initSACAgent[MyQNet[float32]](Gamma, Lr, Epsilon, Reg, BufferSize, BatchSize, ConvCh, ConvW, ConvH, linearStateSize, ActionSize)
  loadLatestModel(trainAgent, modelDir)
  # var opponent = initSACAgent[MyQNet[float32]](Gamma, Lr, Epsilon, Reg, BufferSize, BatchSize, ConvCh, ConvW, ConvH, linearStateSize, ActionSize)

  for ep in 0..<nEpisodes:
    env.reset()
    # loadRandomModel(opponent, modelDir)
    var
      (cState, lState) = env.getObs(0)
      mask = env.getMask(0)
      done = false

    for i in 0..maxEpiLen:
      for a in 1..1:
        let
          (aCState, aLState) = env.getObs(a)
          aMask = env.getMask(a)
        let
          aAction = trainAgent.getAction(aCState, aLState, aMask)
        env.setAction(a, aAction)
      for e in 2..3:
        let
          (eCState, eLState) = env.getObs(e)
          eMask = env.getMask(e)
          eAction = trainAgent.getAction(eCState, eLState, eMask)
        env.setAction(e, eAction)

      let action = trainAgent.getAction(cState, lState, mask)
      env.setAction(0, action)
      var
        nextCState, nextLState: Tensor[float32]
        reward: float32

      # discard env.step(oppAction, false)
      env.step()

      (nextCState, nextLState) = env.getObs(0)
      (reward, done) = (env.getReward(0), env.isTerminated())

      trainAgent.replayBuffer.add(cState, lState, nextCState, nextLState, action, reward, done, mask)
      # if i mod 10 == 0:
      trainAgent.update(cState, lState, nextCState, nextLState, action, reward, done, mask)
      (cState, lState, mask) = (nextCState, nextLState, env.getMask(0))
      if done:
        var totReward = 0'f32
        for j in 0..i:
          var idxInBuffer = trainAgent.replayBuffer.idx - 1 - j
          if idxInBuffer < 0: idxInBuffer += trainAgent.replayBuffer.capacity
          totReward = trainAgent.replayBuffer.rewards[idxInBuffer] + trainAgent.gamma * totReward
          trainAgent.replayBuffer.add(idxInBuffer, totReward)
        break
    if ep mod saveInterval == 0:
      let path = joinPath("models", format(now(), "yyyy-MM-dd-HH-mm"))
      createDir(path)
      save(trainAgent.qnet, trainAgent.logAlpha.value[0], path)


const ModelDir = "models"

train(10000, 60 * 60 + 1, 100, ModelDir)