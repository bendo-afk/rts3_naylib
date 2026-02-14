import os, sequtils, random, algorithm, std/monotimes
import arraymancer
import notsac

let modelDir = "models"




# let
#   episodes =10000
#   maxEpiLen = 1000
# var
#   env = initGame("human")
#   trainAgent = initSACAgent()
#   opponent = initSACAgent()
# for ep in 0..<episodes:
#   var
#     state = env.reset()
#     done = false
#   loadLatestModel(opponent, modelDir)
#   for i in 0..maxEpiLen:
#     let
#       oppAction = opponent.getAction(state)
#       action = trainAgent.getAction(state)
#     var
#       nextState: Tensor[float32]
#       reward: float32

#     discard env.step(oppAction, false)
#     (nextState, reward, done) = env.step(action, true)

#     trainAgent.update(state, nextState, action, reward, done)
#     state = nextState
#     if done:
#       var totReward = 0'f32
#       for j in 0..i:
#         var idxInBuffer = trainAgent.replayBuffer.idx - 1 - j
#         if idxInBuffer < 0: idxInBuffer += trainAgent.replayBuffer.capacity
#         totReward = trainAgent.replayBuffer.rewards[idxInBuffer] + trainAgent.gamma * totReward
#         trainAgent.replayBuffer.add(idxInBuffer, totReward)
#       break
#   if ep mod 50 == 0:
#     let path = joinPath("models", $getMonoTime())
#     createDir(path)
#     save(trainAgent.qnet, path)
