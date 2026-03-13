import torch
from lerobot.policies.diffusion.configuration_diffusion import DiffusionConfig
from lerobot.policies.diffusion.modeling_diffusion import DiffusionPolicy
from lerobot.envs.factory import make_env
from lerobot.envs.configs import PushtEnv
import rerun as rr

def run_trained_model():
    print("🚀 Loading pre-trained Diffusion model for PushT...")
    preload_id = "lerobot/diffusion_pusht"
    
    # 1. Setup the environment (the virtual world)
    env_dict = make_env(PushtEnv(), n_envs=1)
    env = env_dict["pusht"][0]
    
    # 2. Load the pre-trained "Brain" (Policy) from Hugging Face
    policy = DiffusionPolicy.from_pretrained(preload_id)
    policy.eval() # Set to evaluation mode
    
    if torch.cuda.is_available():
        policy.to("cuda")
    elif torch.backends.mps.is_available():
        policy.to("mps")

    print("🤖 Starting autonomous control... Open Rerun to watch!")
    
    # Relaunch Rerun visualization
    rr.init("solve_pusht", spawn=True)
    
    observation, info = env.reset()
    done = False
    
    while not done:
        # Convert observation to torch tensor for the brain
        observation_tensor = {
            "observation.image": torch.from_numpy(observation["observation.image"]).unsqueeze(0),
            "observation.state": torch.from_numpy(observation["observation.state"]).unsqueeze(0),
        }
        
        # Move to correct device
        if torch.cuda.is_available():
            observation_tensor = {k: v.to("cuda") for k, v in observation_tensor.items()}
        elif torch.backends.mps.is_available():
            observation_tensor = {k: v.to("mps") for k, v in observation_tensor.items()}
            
        # The Model thinks and produces an action!
        with torch.no_grad():
            action = policy.select_action(observation_tensor)
        
        # Apply the action to the world
        observation, reward, done, truncated, info = env.step(action[0].cpu().numpy())
        
        if done or truncated:
            break

    print("✅ Task complete!")

if __name__ == "__main__":
    run_trained_model()
