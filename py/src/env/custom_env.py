from typing import Optional
import gymnasium as gym
from gymnasium import spaces
import numpy as np
import myenv


class MyEnv(gym.Env):
    def __init__(self, render_mode):
        self.render_mode = render_mode

        self.observation_space = spaces.Dict({
            "self":  spaces.Box(low=-np.inf, high=np.inf, shape=(15,), dtype=np.float32),
            "allies": spaces.Box(low=-np.inf, high=np.inf, shape=(7 - 1, 15), dtype=np.float32),
            "enemies": spaces.Box(low=-np.inf, high=np.inf, shape=(7, 15), dtype=np.float32),
            
            "maps": spaces.Box(low=0, high=1, shape=(1 + 4 + 4, 20, 20), dtype=np.float32),
            
            "match_time": spaces.Box(low=0, high=np.inf, shape=(1,), dtype=np.float32)
        })
    
        self.action_space = gym.spaces.MultiDiscrete([21, 3])

        aParam = (2, 2, 10, 1, 0)
        aParams = [aParam]
        myenv.initEnv(aParams, [], render_mode == "human")



    def get_observation(self, unit_id, is_ally):
        self_obs = np.array(myenv.getObsOfSelf(unit_id), dtype=np.float32)
        
        other_units_obs = get_padded_obs(unit_id, [], [])
        allies_obs = np.array(other_units_obs[0], dtype=np.float32)
        enemies_obs = np.array(other_units_obs[1], dtype=np.float32)


        h_map = np.array(myenv.getObsHeight(), dtype=np.float32)        # (20, 20)
        u_map = np.array(myenv.getObsUnitsMap(unit_id), dtype=np.float32) # (4, 20, 20)
        s_map = np.array(myenv.getObsScoreMap(is_ally), dtype=np.float32) # (4, 20, 20)
        
        # チャンネル方向にスタック (1+4+4 = 9 layers)
        combined_maps = np.concatenate([
            h_map[np.newaxis, :, :], 
            u_map, 
            s_map
        ], axis=0)

        return {
            "self": self_obs,
            "allies": allies_obs,
            "enemies": enemies_obs,
            "maps": combined_maps,
            "match_time": np.array([myenv.getLeftMatchTime()], dtype=np.float32)
        }


    def reset(self, seed: Optional[int] = None, options: Optional[dict] = None):
        super().reset(seed=seed)

        myenv.reset()

        observation = self.get_observation(0, True)
        info = {}
        return observation, info
  

    def step(self, action):
        if self.render_mode == "human":
            myenv.draw()

        myenv.setAction(0, action[0], action[1])
        myenv.step()

        observation = self.get_observation(0, True)
        terminated = myenv.isTerminated()
        truncated = False
        reward = myenv.getReward(0)
        info = {}

        return observation, reward, terminated, truncated, info
  

    def render(self):
        if self.render_mode == "human":
            myenv.draw()

    def action_masks(self):
        mask0 = np.array(myenv.getActionMask(0), dtype=bool)
        
        mask1 = np.ones(3, dtype=bool)

        return np.concatenate([mask0, mask1])


def get_padded_obs(self_id, ally_ids, enemy_ids):
    allies_obs = []
    for a_id in ally_ids:
        if a_id != self_id:
            allies_obs.append(env.getObsAlly(self_id, a_id))
    
    while len(allies_obs) < (7 - 1):
        pad = np.zeros(15, dtype=np.float32)
        pad[0] = 1.0
        allies_obs.append(pad)

    enemies_obs = []
    for e_id in enemy_ids:
        enemies_obs.append(env.getObsEnemy(self_id, e_id))
    
    while len(enemies_obs) < 7:
        pad = np.zeros(15, dtype=np.float32)
        pad[0] = 1.0
        enemies_obs.append(pad)

    return np.array(allies_obs), np.array(enemies_obs)



gym.register(
    id="gymnasium_env/rts3-v0",
    entry_point=MyEnv,
    max_episode_steps=60 * 60 * 3 + 1
)


env = gym.make("gymnasium_env/rts3-v0", render_mode="human")

from gymnasium.utils.env_checker import check_env

# This will catch many common issues
try:
    check_env(env.unwrapped)
    print("Environment passes all checks!")
except Exception as e:
    print(f"Environment has issues: {e}")