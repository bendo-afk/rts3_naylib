from stable_baselines3 import PPO

# model = PPO("MlpPolicy", env, verbose=1)

# model.learn(total_timesteps=50000)

# model.save("ppov1")

# model = PPO.load("ppov1")
# model.set_env(env)

# model.learn(total_timesteps=50000)
# model.save("ppov2")


model = PPO.load("models/ppov5")
model.set_env(env)

model.learn(total_timesteps=50000)

