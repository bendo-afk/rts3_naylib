from pathlib import Path
import gymnasium as gym
from sb3_contrib import MaskablePPO
from sb3_contrib.common.maskable.policies import MaskableMultiInputActorCriticPolicy
import env.selfplay

env = gym.make("gymnasium_env/rts3-v1", render_mode="none")

# model = MaskablePPO(
#     policy=MaskableMultiInputActorCriticPolicy,
#     env=env,
#     verbose=1,
# )
# model.learn(total_timesteps=50_000)
# model.save("models/p0")

# model = MaskablePPO.load("models/p0")
# model.set_env(env)
# model.learn(total_timesteps=30000)
# model.save("p0v1")

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
    return MaskablePPO.load(latest_file)


from datetime import datetime

training_iterations = 1
for i in range(training_iterations):
  model = get_latest_model()
  model.set_env(env)
  model.learn(total_timesteps=50_000)

  timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
  save_name = f"models/phase1_{timestamp}"

  model.save(save_name)