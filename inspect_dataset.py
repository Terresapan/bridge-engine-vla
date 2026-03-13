import torch
from lerobot.datasets.lerobot_dataset import LeRobotDataset
import json

def inspect_dataset(repo_id):
    print(f"🔍 Loading dataset: {repo_id}...")
    
    # Load dataset (this will download/cache it)
    dataset = LeRobotDataset(repo_id)
    
    print("\n📊 Dataset Overview:")
    print(f"Repository: {repo_id}")
    print(f"Number of episodes: {dataset.num_episodes}")
    print(f"Number of samples: {len(dataset)}")
    print(f"FPS: {dataset.fps}")
    
    print("\n🛠 Features (State/Action Schema):")
    for feature_name, feature_info in dataset.features.items():
        print(f" - {feature_name}: {feature_info}")

    print("\n📈 Statistics (Mean/Std for Normalization):")
    # Safer way to show stats keys
    stats = dataset.meta.stats
    stats_keys = list(stats.keys())
    for key in stats_keys[:3]: # Show first 3 keys
        print(f" - {key}: {type(stats[key])}")

    print("\n✅ Sample Data (Index 0):")
    sample = dataset[0]
    for key, value in sample.items():
        if hasattr(value, "shape"):
            print(f" - {key}: Shape {value.shape}")
        else:
            print(f" - {key}: {value}")

if __name__ == "__main__":
    # Starting with a lightweight static dataset
    inspect_dataset("lerobot/aloha_sim_transfer_cube_scripted")
