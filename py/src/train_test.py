import gymnasium as gym
from sb3_contrib import MaskablePPO
from sb3_contrib.common.maskable.utils import get_action_masks
from sb3_contrib.common.maskable.policies import MaskableMultiInputActorCriticPolicy
import env.custom_env


# model = PPO("MlpPolicy", env, verbose=1)

# model.learn(total_timesteps=50000)

# model.save("ppov1")

# model = PPO.load("ppov1")
# model.set_env(env)

# model.learn(total_timesteps=50000)
# model.save("ppov2")


# model = PPO.load("models/ppov5")
# model.set_env(env)

# model.learn(total_timesteps=50000)


env = gym.make("gymnasium_env/rts3-v0", render_mode="human")

model = MaskablePPO(
    policy=MaskableMultiInputActorCriticPolicy,
    env=env,
    verbose=1,
)

model.learn(total_timesteps=100_000)