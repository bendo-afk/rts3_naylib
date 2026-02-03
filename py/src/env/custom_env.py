from typing import Optional
import gymnasium as gym
import numpy as np
import mymodule

class MyEnv(gym.Env):
  def __init__(self, render_mode):
    self.render_mode = render_mode

    self.observation_space = gym.spaces.Dict({
      
    })
        
    self.action_space = gym.spaces.Discrete(4)
    mymodule.initGame()


  def get_obs(self):
    # Nimから届いた list を numpy 配列に変換
    return np.array(mymodule.getObs(), dtype=np.float64)


  def reset(self, seed: Optional[int] = None, options: Optional[dict] = None):
    super().reset(seed=seed)

    mymodule.reset()

    observation = self.get_obs()
    info = {}

    return observation, info
  

  def step(self, action):
    if self.render_mode == "human":
      mymodule.draw()

    mymodule.step(action, 1)

    terminated = mymodule.isTerminated()
    truncated = False
    reward = mymodule.getReward()
    observation = self.get_obs()
    info = {}

    return observation, reward, terminated, truncated, info
  

  def render(self):
    if self.render_mode == "human":
      mymodule.draw()


gym.register(
  id="gymnasium_env/test-v0",
  entry_point=MyEnv,
  max_episode_steps=300
)


env = gym.make("gymnasium_env/test-v0", render_mode="human")

from gymnasium.utils.env_checker import check_env

# This will catch many common issues
try:
    check_env(env.unwrapped)
    print("Environment passes all checks!")
except Exception as e:
    print(f"Environment has issues: {e}")