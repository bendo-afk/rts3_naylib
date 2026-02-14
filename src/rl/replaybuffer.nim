import arraymancer
import random

randomize()

type
  ReplayBuffer* = object of RootObj
    convStates*: Tensor[float32]
    linearStates*: Tensor[float32]
    nextConvStates*: Tensor[float32]
    nextLinearStates*: Tensor[float32]
    actions*: Tensor[int]
    rewards*: Tensor[float32]
    dones*: Tensor[float32]

    idx*: int
    count*: int
    capacity*: int


proc newReplayBuffer*(capacity, convCh, convW, convH, linearStateSize, actionSize: int): ReplayBuffer =
  result.capacity = capacity
  result.convStates = newTensor[float32](capacity, convCh, convW, convH)
  result.linearStates = newTensor[float32](capacity, linearStateSize)
  result.nextConvStates = newTensor[float32](capacity, convCh, convW, convH)
  result.nextLinearStates = newTensor[float32](capacity, linearStateSize)
  result.actions = newTensor[int](capacity)
  result.rewards = newTensor[float32](capacity)
  result.dones = newTensor[float32](capacity)


proc add*(rb: var ReplayBuffer, cs, ls, ncs, nls: Tensor[float32], a: int, r: float32, done: bool) =
  let i = rb.idx
  rb.convStates[i, _] = cs
  rb.linearStates[i, _] = ls
  rb.nextConvStates[i, _] = ncs
  rb.nextLinearStates[i, _] = nls
  rb.actions[i] = a.int32
  rb.rewards[i] = r
  rb.dones[i] = done.float32

  rb.idx = (rb.idx + 1) mod rb.capacity
  rb.count = min(rb.count + 1, rb.capacity)


proc sample*(rb: ReplayBuffer, batchSize: int): tuple[cs, ls, ncs, nls: Tensor[float32], a: Tensor[int], r, d: Tensor[float32]] =
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



# when isMainModule:
#   import envs/testenv
#   var
#     env = initGame("human")
#     replayBuffer = newReplayBuffer(5000, StateSize, ActionSize)

#   for ep in 0..<100:
#     var
#       state = env.reset()
#       done = false

#     while not done:
#       let
#         action = 2
#       var
#         nextState: Tensor[float32]
#         reward: float32
#       (nextState, reward, done) = env.step(action, true)
#       replayBuffer.add(state, nextState, action, reward, done)
#       state = nextState
      
#   let (state, action, reward, nextState, done) = replayBuffer.sample(60)

#   echo state.shape
#   echo action.shape
#   echo reward.shape
#   echo nextState.shape
#   echo done.shape
#   echo state