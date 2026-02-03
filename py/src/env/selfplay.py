import random
from typing import Optional
from pathlib import Path
import gymnasium as gym
import numpy as np
import mymodule
from stable_baselines3 import PPO

class MyEnv(gym.Env):

  # metadata = {"render_modes": ["none", "human"]}

  def __init__(self, render_mode):
    self.render_mode = render_mode
    self.observation_space = gym.spaces.Box(0, 1000, shape=(4,), dtype=float)
    self.action_space = gym.spaces.Discrete(4)
    mymodule.initGame()
    
    self.opponent_model = None
    self.model_pool_path = Path("models/")

  def get_obs(self, is_ally: bool):
    # Nimから届いた list を numpy 配列に変換
    return np.array(mymodule.getObs(is_ally), dtype=np.float64)


  def set_random_model(self):
    model_files = list(self.model_pool_path.glob("*.zip"))
    if model_files:
      selected_path = random.choice(model_files)
      # 相手用モデルとしてロード（推論専用）
      self.opponent_model = PPO.load(selected_path)
      print(selected_path)

  def reset(self, seed: Optional[int] = None, options: Optional[dict] = None):
    super().reset(seed=seed)

    self.set_random_model()

    mymodule.reset()
    return self.get_obs(True), {}
  

  def step(self, action):
    if self.render_mode == "human":
      mymodule.draw()

    mymodule.step(action, True)

    opp_obs = self.get_obs(False)
    opp_action, _ = self.opponent_model.predict(opp_obs, deterministic=False)
    mymodule.step(opp_action, False)

    terminated = mymodule.isTerminated()
    truncated = False
    reward = mymodule.getReward(True)
    observation = self.get_obs(True)
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



# model = PPO("MlpPolicy", env, verbose=1)
# model.learn(total_timesteps=50000)
# model.save("ppov1")

# model = PPO.load("ppov1")
# model.set_env(env)
# model.learn(total_timesteps=50000)
# model.save("ppov2")


def get_latest_model(model_dir: str = "models/"):
    path = Path(model_dir)
    # ディレクトリ内のzipファイルをすべて取得
    files = list(path.glob("*.zip"))
    if not files:
        return None
    # 更新日時が新しい順にソートして、先頭を返す
    latest_file = max(files, key=lambda f: f.stat().st_mtime)
    return PPO.load(latest_file)


from datetime import datetime

training_iterations = 10
for i in range(training_iterations):
  model = get_latest_model()
  model.set_env(env)
  model.learn(total_timesteps=10000)

  timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
  save_name = f"models/ppo_{timestamp}"

  model.save(save_name)