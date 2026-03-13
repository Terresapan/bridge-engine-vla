import torch
from lerobot.policies.act.modeling_act import ACTPolicy
from lerobot.envs.factory import make_env, make_env_pre_post_processors
from lerobot.envs.configs import AlohaEnv
from lerobot.policies.factory import make_pre_post_processors
from lerobot.envs.utils import preprocess_observation
import rerun as rr

def run_trained_aloha():
    print("🚀 Loading pre-trained ACT model for ALOHA Transfer Cube...")
    preload_id = "lerobot/act_aloha_sim_transfer_cube_human"
    
    # 1. Setup the environment
    print("🌍 Booting up MuJoCo Physics Engine...")
    env_cfg = AlohaEnv(task="AlohaTransferCube-v0")
    env_dict = make_env(env_cfg, n_envs=1)
    env = env_dict["aloha"][0]
    
    # 2. Load the Policy
    policy = ACTPolicy.from_pretrained(preload_id)
    policy.eval()
    
    if torch.cuda.is_available():
        policy.to("cuda")
    elif torch.backends.mps.is_available():
        policy.to("mps")

    # The older v0.4.0 ACT checkpoints have their normalization inside the safetensors, 
    # so we'll load them manually since v0.5.0 expects a policy_preprocessor.json
    from huggingface_hub import hf_hub_download
    from safetensors.torch import load_file
    sf_path = hf_hub_download(preload_id, "model.safetensors")
    sf_dict = load_file(sf_path)
    
    dev = next(policy.parameters()).device
    def get_norm(key): return sf_dict[key].to(dev)
    
    img_mean = get_norm("normalize_inputs.buffer_observation_images_top.mean").view(1, 3, 1, 1)
    img_std = get_norm("normalize_inputs.buffer_observation_images_top.std").view(1, 3, 1, 1)
    state_mean = get_norm("normalize_inputs.buffer_observation_state.mean").view(1, 14)
    state_std = get_norm("normalize_inputs.buffer_observation_state.std").view(1, 14)
    action_mean = get_norm("unnormalize_outputs.buffer_action.mean").view(1, 14)
    action_std = get_norm("unnormalize_outputs.buffer_action.std").view(1, 14)

    print("🤖 Starting autonomous control...")
    
    observation, info = env.reset()
    done = False
    frames = []
    
    while not done:
        # Manual Preprocessing
        img = torch.from_numpy(observation["pixels"]["top"]).float() / 255.0
        if img.shape[-1] == 3: img = img.permute(0, 3, 1, 2)
        state = torch.from_numpy(observation["agent_pos"]).float()
        
        obs_dict = {
            "observation.images.top": (img.to(dev) - img_mean) / img_std,
            "observation.state": (state.to(dev) - state_mean) / state_std,
        }
        
        # Determine the action
        with torch.inference_mode():
            action = policy.select_action(obs_dict)
            
        # Manual Postprocessing (Action unnormalization)
        action_real = action * action_std + action_mean
        action_numpy = action_real.cpu().numpy()
        
        # Apply the action
        observation, reward, done, truncated, info = env.step(action_numpy)
        
        # Capture frame
        frame = observation["pixels"]["top"]
        if frame.ndim == 4: frame = frame[0]
        if frame.shape[0] == 3: 
            import numpy as np
            frame = np.transpose(frame, (1, 2, 0))
        frames.append(frame)
        
        if done or truncated:
            break

    print(f"✅ Task complete in {len(frames)} frames! Saving video...")
    import imageio
    imageio.mimsave("aloha_demo.mp4", frames, fps=50)
    print("🎥 Saved video to aloha_demo.mp4! Double-click it on your Mac to view.")

if __name__ == "__main__":
    run_trained_aloha()
