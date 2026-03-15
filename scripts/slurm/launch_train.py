#!/usr/bin/env python3
"""Launch script for Trinity blend training.

Bypasses draccus CLI parsing issues with union-typed list fields
(str | list[str]) by constructing the config programmatically.
"""
import os
from pathlib import Path

from lerobot.configs.default import DatasetConfig, WandBConfig
from lerobot.configs.train import TrainPipelineConfig
from lerobot.policies.factory import make_policy_config
from lerobot.scripts.lerobot_train import train


def main():
    # Read from environment (set by run.env / sbatch --export)
    repo_ids = [
        os.environ.get("DATASET_REPO_1", "lerobot/aloha_mobile_cabinet"),
        os.environ.get("DATASET_REPO_2", "lerobot/svla_so100_sorting"),
        os.environ.get("DATASET_REPO_3", "lerobot/svla_so100_pickplace"),
    ]
    sampling_weights = [
        float(os.environ.get("SAMPLING_WEIGHT_1", "0.5")),
        float(os.environ.get("SAMPLING_WEIGHT_2", "0.3")),
        float(os.environ.get("SAMPLING_WEIGHT_3", "0.2")),
    ]
    run_dir = os.environ["RUN_DIR"]
    policy_type = os.environ.get("POLICY_TYPE", "smolvla")
    batch_size = int(os.environ.get("BATCH_SIZE", "64"))
    train_steps = int(os.environ.get("TRAIN_STEPS", "120000"))
    save_freq = int(os.environ.get("SAVE_FREQ", "5000"))
    scheduler_decay_steps = int(os.environ.get("SCHEDULER_DECAY_STEPS", "120000"))
    wandb_enable = os.environ.get("WANDB_ENABLE", "true").lower() == "true"
    wandb_project = os.environ.get("WANDB_PROJECT", "bridge-engine")

    policy_cfg = make_policy_config(
        policy_type,
        scheduler_decay_steps=scheduler_decay_steps,
        push_to_hub=False,
    )

    cfg = TrainPipelineConfig(
        dataset=DatasetConfig(
            repo_id=repo_ids,
            sampling_weights=sampling_weights,
            video_backend="pyav",
        ),
        policy=policy_cfg,
        output_dir=Path(run_dir),
        batch_size=batch_size,
        steps=train_steps,
        save_freq=save_freq,
        eval_freq=0,
        wandb=WandBConfig(
            enable=wandb_enable,
            project=wandb_project,
        ),
    )

    train(cfg)


if __name__ == "__main__":
    main()
