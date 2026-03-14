import torch
from lerobot.policies.act.modeling_act import ACTPolicy
from lerobot.envs.factory import make_env, make_env_pre_post_processors
from lerobot.envs.configs import AlohaEnv
from lerobot.policies.factory import make_pre_post_processors
from lerobot.envs.utils import preprocess_observation
import rerun as rr

def run_trained_aloha():
    print("🚀 Loading pre-trained ACT model for ALOHA Transfer Cube...")
    # 🔽 CHANGE THIS 🔽 to your Hugging Face username (e.g., "terresa/aloha_act_sim_transfer_cube")
    # This automatically downloads your 207MB model.safetensors directly from your account!
    preload_id = "Terresa/my-first-act-aloha"
    
    # 1. Setup the environment
    print("🌍 Booting up MuJoCo Physics Engine...")
    env_cfg = AlohaEnv(task="AlohaTransferCube-v0")
    env_dict = make_env(env_cfg, n_envs=1)
    env = env_dict["aloha"][0]
    
    # 2. Load the Policy
    policy = ACTPolicy.from_pretrained(preload_id)
    policy.eval()
    
    dev = next(policy.parameters()).device
    if torch.cuda.is_available(): dev = "cuda"
    elif torch.backends.mps.is_available(): dev = "mps"
    policy.to(dev)

    # 3. Load Normalization Stats (v0.5.0 style)
    from huggingface_hub import hf_hub_download
    from safetensors.torch import load_file
    stats_file = "policy_preprocessor_step_3_normalizer_processor.safetensors"
    try:
        stats_path = hf_hub_download(preload_id, stats_file)
    except:
        # Fallback for some older v0.5 naming schemes
        stats_path = hf_hub_download(preload_id, "policy_preprocessor.safetensors")
    
    stats = load_file(stats_path)
    
    def get_stat(key): return stats[key].to(dev)
    
    img_mean = get_stat("observation.images.top.mean").view(1, 3, 1, 1)
    img_std = get_stat("observation.images.top.std").view(1, 3, 1, 1)
    state_mean = get_stat("observation.state.mean").view(1, 14)
    state_std = get_stat("observation.state.std").view(1, 14)
    action_mean = get_stat("action.mean").view(1, 14)
    action_std = get_stat("action.std").view(1, 14)

    print("🤖 Starting autonomous control...")
    
    observation, info = env.reset()
    done = False
    frames = []
    
    while not done:
        # 1. Format Image (H,W,C -> 1,C,H,W)
        img = torch.from_numpy(observation["pixels"]["top"]).float() / 255.0
        if img.ndim == 3: img = img.permute(2, 0, 1).unsqueeze(0)
        elif img.ndim == 4: img = img.permute(0, 3, 1, 2)
            
        # 2. Format State (1,14)
        state = torch.from_numpy(observation["agent_pos"]).float()
        if state.ndim == 1: state = state.unsqueeze(0)
        
        # 3. Apply Normalization
        obs_dict = {
            "observation.images.top": (img.to(dev) - img_mean) / img_std,
            "observation.state": (state.to(dev) - state_mean) / state_std,
        }
        
        # 4. Predict
        with torch.inference_mode():
            action = policy.select_action(obs_dict)
            
        # 5. Unnormalize Action
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
    imageio.mimsave("aloha_demo_real.mp4", frames, fps=50)
    print("🎥 Saved video to aloha_demo_real.mp4! Double-click it on your Mac to view.")

if __name__ == "__main__":
    run_trained_aloha()
