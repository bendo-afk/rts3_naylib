import random
from typing import Optional
from pathlib import Path
import gymnasium as gym
from gymnasium import spaces
import numpy as np
import myenv_multi as myenv
from sb3_contrib import MaskablePPO

class MyEnv(gym.Env):
    def __init__(self, render_mode):
        self.render_mode = render_mode

        self.observation_space = spaces.Dict({
            "allies": spaces.Box(low=-np.inf, high=np.inf, shape=(7, 15), dtype=np.float32),
            "enemies": spaces.Box(low=-np.inf, high=np.inf, shape=(7, 15), dtype=np.float32),
            "maps": spaces.Box(low=0, high=1, shape=(1 + 3 + 4, 20, 20), dtype=np.float32),
            "match_time": spaces.Box(low=0, high=np.inf, shape=(1,), dtype=np.float32)
        })
        self.action_space = gym.spaces.MultiDiscrete([21, 3] * 7)

        aParam = (2, 2, 10, 1, 0)
        aParams = [aParam]
        myenv.initEnv(aParams, [], render_mode == "human")

        self.initialized = False
        self.opponent_model = None
        self.model_pool_path = Path("models/")
        self.is_curr_ally = True
        self.n_ally = 1
        self.n_enemy = 0

    
    def get_observation(self, is_ally):
        
        other_units_obs = get_padded_obs(is_ally, self.n_ally, self.n_enemy)
        allies_obs = np.array(other_units_obs[0], dtype=np.float32)
        enemies_obs = np.array(other_units_obs[1], dtype=np.float32)

        h_map = np.array(myenv.getObsHeight(), dtype=np.float32)        # (20, 20)
        u_map = np.array(myenv.getObsUnitsMap(is_ally), dtype=np.float32) # (3, 20, 20)
        s_map = np.array(myenv.getObsScoreMap(is_ally), dtype=np.float32) # (4, 20, 20)
        
        combined_maps = np.concatenate([
            h_map[np.newaxis, :, :], 
            u_map, 
            s_map
        ], axis=0)

        return {
            "allies": allies_obs,
            "enemies": enemies_obs,
            "maps": combined_maps,
            "match_time": np.array([myenv.getLeftMatchTime()], dtype=np.float32)
        }


    def set_random_model(self):
        model_files = list(self.model_pool_path.glob("*.zip"))
        if model_files:
            selected_path = random.choice(model_files)
            # 相手用モデルとしてロード（推論専用）
            self.opponent_model = MaskablePPO.load(selected_path)
            print(selected_path)


    def reset(self, seed: Optional[int] = None, options: Optional[dict] = None):
        super().reset(seed=seed)

        self.set_random_model()

        myenv.reset()
        self.initialized = True
        return self.get_observation(True), {}
  

    def step(self, action):
        self.set_actions(action, True)

        # self.is_curr_ally = False
        # opp_obs = self.get_observation(False)
        # masks = self.action_masks()
        # opp_action, _ = self.opponent_model.predict(opp_obs, deterministic=False, action_masks=masks)
        # self.set_actions(opp_action, False)
        # self.is_curr_ally = True

        myenv.step()

        observation = self.get_observation(True)
        terminated = myenv.isTerminated()
        truncated = False
        reward = myenv.getReward(True)
        info = {}

        if self.render_mode == "human" and self.initialized:
            myenv.draw()

        return observation, reward, terminated, truncated, info


    def set_actions(self, action, is_ally):
        if is_ally:
            for i in range(self.n_ally):
                myenv.setAction(i, action[2 * i], action[2 * i + 1])
        else:
            for i in range(self.n_enemy):
                myenv.setAction(i + self.n_ally, action[2 * i], action[2 * i + 1])
          

    def action_masks(self):
        masks_list = []
        pad = np.zeros(24, dtype=bool)
        pad[6] = True
        pad[21] = True 
        if self.is_curr_ally:
            start_id, count = 0, self.n_ally
        else:
            start_id, count = self.n_ally, self.n_enemy

        for i in range(count):
            masks_list.append(np.array(myenv.getActionMask(start_id + i), dtype=bool))    
        while len(masks_list) < 7:
            masks_list.append(pad)

        return np.concatenate(masks_list).flatten()


def get_padded_obs(is_ally, n_ally, n_enemy):
    allies_obs = []
    for id in range(n_ally):
        allies_obs.append(myenv.getObsAlly(id))
    while len(allies_obs) < 7:
        pad = np.zeros(15, dtype=np.float32)
        pad[0] = 1.0
        allies_obs.append(pad)

    enemies_obs = []
    for id in range(n_enemy):
        enemies_obs.append(myenv.getObsEnemy(id + n_ally))
    while len(enemies_obs) < 7:
        pad = np.zeros(15, dtype=np.float32)
        pad[0] = 1.0
        enemies_obs.append(pad)

    return np.array(allies_obs), np.array(enemies_obs)



gym.register(
    id="gymnasium_env/rts3-v1",
    entry_point=MyEnv,
    max_episode_steps=60 * 60 * 3 + 1
)


# env = gym.make("gymnasium_env/rts3-v0", render_mode="human")

# from gymnasium.utils.env_checker import check_env

# # This will catch many common issues
# try:
#     check_env(env.unwrapped)
#     print("Environment passes all checks!")
# except Exception as e:
#     print(f"Environment has issues: {e}")


