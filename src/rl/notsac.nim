import random, sequtils, math, os
import arraymancer
import replaybuffer
import gates_exp

randomize()


type
  NoTarRepBuffer = object of ReplayBuffer
    totalRewards: Tensor[float32]
    masks: Tensor[float32]

proc add*(rb: var NoTarRepBuffer, cs, ls, ncs, nls: Tensor[float32], a: int, r: float32, done: bool, m: Tensor[float32]) =
  let i = rb.idx
  rb.convStates[i, _] = cs.unsqueeze(0)
  rb.linearStates[i, _] = ls.unsqueeze(0)
  rb.nextConvStates[i, _] = ncs.unsqueeze(0)
  rb.nextLinearStates[i, _] = nls.unsqueeze(0)
  rb.actions[i] = a.int32
  rb.rewards[i] = r
  rb.dones[i] = done.float32
  rb.masks[i, _] = m

  rb.idx = (rb.idx + 1) mod rb.capacity
  rb.count = min(rb.count + 1, rb.capacity)


proc add*(rb: var NoTarRepBuffer, idx: int, totReward: float32) =
  rb.totalRewards[idx] = totReward

proc newNoTarRepBuffer*(capacity, convCh, convW, convH, linearStateSize, actionSize: int): NoTarRepBuffer =
  result.capacity = capacity
  result.convStates = newTensor[float32](capacity, convCh, convW, convH)
  result.linearStates = newTensor[float32](capacity, linearStateSize)
  result.nextConvStates = newTensor[float32](capacity, convCh, convW, convH)
  result.nextLinearStates = newTensor[float32](capacity, linearStateSize)
  result.actions = newTensor[int](capacity)
  result.rewards = newTensor[float32](capacity)
  result.dones = newTensor[float32](capacity)
  result.totalRewards = newTensor[float32](capacity)
  result.masks = newTensor[float32](capacity, actionSize)

proc sample*(rb: NoTarRepBuffer, batchSize: int): tuple[cs, ls, ncs, nls: Tensor[float32], a: Tensor[int], r, d, tr, m: Tensor[float32]] =
  var indices = newTensor[int](batchSize)
  for i in 0..<batchSize:
    indices[i] = rand(rb.count - 1)
  
  result.cs = rb.convStates[indices]
  result.ls = rb.linearStates[indices]
  result.ncs = rb.nextConvStates[indices]
  result.nls = rb.nextLinearStates[indices]
  result.a = rb.actions[indices]
  result.r = rb.rewards[indices]
  result.d = rb.dones[indices]
  result.tr = rb.totalRewards[indices]
  result.m = rb.masks[indices]


network QNet:
  layers stateSize, actionSize:
    l1: Linear(stateSize, 64)
    l2: Linear(64, actionSize)
  forward x:
    x.l1.relu.l2


type
  NoTSACAgent*[QNET] = object
    gamma* = 0.98'f32
    lr = 0.0005'f32
    epsilon = 0.3
    bufferSize = 10000
    batchSize = 100
    reg = 0.1'f32

    nAction: int

    logAlpha: Variable[Tensor[float32]]
    alpha: float32
    alphaOptimizer: Adam[Tensor[float32]]
    targetEntropy: float32

    replayBuffer*: NoTarRepBuffer
    ctx*: Context[Tensor[float32]]
    qnet*: QNET
    optimizer: Adam[Tensor[float32]]


proc initSACAgent*[QNET](gamma, lr, epsilon, reg: float32, bufferSize, batchSize, convCh, convW, convH, linearStateSize, nAction: int): NoTSACAgent[QNET] =
  result.gamma = gamma
  result.lr = lr
  result.epsilon = epsilon
  result.reg = reg
  result.bufferSize = bufferSize
  result.batchSize = batchSize
  result.nAction = nAction
  result.ctx = newContext Tensor[float32]
  result.qnet = result.ctx.init(QNET)
  result.optimizer = result.qnet.optimizer(Adam, result.lr)
  result.replayBuffer = newNoTarRepBuffer(result.bufferSize, convCh, convW, convH, linearStateSize, nAction)

  result.logAlpha = result.ctx.variable(zeros[float32](1), requires_grad = true)
  result.alpha = result.logAlpha.value[0].exp
  result.alphaOptimizer = result.logAlpha.optimizer(Adam, result.lr)
  result.targetEntropy = 0.98 * ln(nAction.float32)


proc getAction*(self: NoTSACAgent, cs, ls, mask: Tensor[float32]): int =
  let
    ms = cs.unsqueeze(0)
    vs = ls.unsqueeze(0)
    qs = self.qnet.forward(self.ctx.variable(ms, false), self.ctx.variable(vs, false)).value
    probs = softmax(qs / self.alpha + mask.unsqueeze(0)).squeeze(0).toSeq1D
    actions = toSeq(0..<probs.len)
    action = sample(actions, probs.cumsummed())
  return action


proc update*(self: var NoTSACAgent, cState, lState, nextCState, nextLState: Tensor[float32], action: int, reward: float32, done: bool, mask: Tensor[float32]) =
  self.replayBuffer.add(cState, lState, nextCState, nextLState, action, reward, done, mask)
  if self.replayBuffer.count < self.batchSize:
    return
  
  let
    (cs, ls, ncs, nls, a, r, d, tr, m) = self.replayBuffer.sample(self.batchSize)
    
    qs = self.qnet.forward(self.ctx.variable(cs, true), self.ctx.variable(ls, true))
  var oneHotRaw = newTensor[float32](self.batchSize, self.nAction)
  for i in 0..<self.batchSize:
    oneHotRaw[i, a[i]] = 1.0'f32
  let
    oneHot = self.ctx.variable(oneHotRaw)
    oneHotQ = qs *. oneHot
    onesRaw = ones[float32](self.nAction, 1)
    onesVar = self.ctx.variable(onesRaw)
    q = (oneHotQ * onesVar).squeeze(1)

    nextQs = self.qnet.forward(self.ctx.variable(ncs, false), self.ctx.variable(nls, false)).value
    alpha = self.alpha
    probs = softmax(nextQs / alpha  + m)
    logProbs = ln(probs +. 1e-8'f32)
    nextV = (probs *. (nextQs - alpha * logProbs)).sum(axis = 1).squeeze(1)
    target = r +. self.gamma * (ones[float32](d.shape) - d) *. nextV
    
    loss = mse_loss(q, target) + mse_loss(q, tr) *. self.ctx.variable([self.reg].toTensor)

  backprop(loss)
  self.optimizer.update()

  let
    curH = -(logProbs *. probs).sum() /. [self.batchSize.float32].toTensor
    alphaLoss = self.ctx.variable(curH) *. self.logAlpha.exp
  backprop(alphaLoss)
  self.alphaOptimizer.update()
  self.alpha = self.logAlpha.value[0].exp




# when isMainModule:
#   let
#     episodes =100
#     maxEpiLen = 1000
#   var
#     env = initGame("human")
#     agent = initSACAgent()
#     rewardHistroy: seq[float32] = @[]
#   for ep in 0..<episodes:
#     var
#       state = env.reset()
#       done = false
#       totalReward = 0'f32
#     for i in 0..maxEpiLen:
#       let
#         action = agent.getAction(state)
#       var
#         nextState: Tensor[float32]
#         reward: float32

#       (nextState, reward, done) = env.step(action, true)

#       agent.update(state, nextState, action, reward, done)
#       state = nextState
#       totalReward += reward
#       if done:
#         var totReward = 0'f32
#         for j in 0..i:
#           var idxInBuffer = agent.replayBuffer.idx - 1 - j
#           if idxInBuffer < 0: idxInBuffer += agent.replayBuffer.capacity
#           totReward = agent.replayBuffer.rewards[idxInBuffer] + agent.gamma * totReward
#           agent.replayBuffer.add(idxInBuffer, totReward)
#         break
#     rewardHistroy.add(totalReward)
  
#     if ep mod 10 == 0:
#       echo agent.alpha
  
#   save(agent.qnet, "models")