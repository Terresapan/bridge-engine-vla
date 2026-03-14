#!/bin/bash
#SBATCH --job-name=bridge-engine-train
#SBATCH --partition=priority
#SBATCH --nodes=1
#SBATCH --gpus=8
#SBATCH --cpus-per-gpu=16
#SBATCH --mem=0
#SBATCH --time=08:00:00
#SBATCH --output=logs/slurm/%x-%j.out
#SBATCH --error=logs/slurm/%x-%j.err

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

source scripts/slurm/run.env

mkdir -p logs/slurm
mkdir -p "$OUTPUT_ROOT"

export HF_HOME
export TMPDIR
export HF_HUB_ENABLE_HF_TRANSFER=1

RUN_DIR="${OUTPUT_ROOT}/${RUN_NAME}"
mkdir -p "$RUN_DIR"

echo "$RUN_DIR" > "$REPO_ROOT/logs/slurm/latest_run_dir.txt"

cat <<EOF
[TRAIN] Host: $(hostname)
[TRAIN] Start: $(date -Iseconds)
[TRAIN] Run name: $RUN_NAME
[TRAIN] Run dir: $RUN_DIR
[TRAIN] Policy: $POLICY_TYPE
EOF

# Optional env activation (uncomment and customize if needed)
# source /mnt/sharefs/$USER/miniconda3/etc/profile.d/conda.sh
# conda activate lerobot

srun lerobot-train \
  --policy.type="$POLICY_TYPE" \
  --dataset.repo_id="$DATASET_REPOS" \
  --dataset.sampling_weights="$SAMPLING_WEIGHTS" \
  --batch_size="$BATCH_SIZE" \
  --steps="$TRAIN_STEPS" \
  --save_freq="$SAVE_FREQ" \
  --eval_freq="$EVAL_FREQ" \
  --wandb.enable="$WANDB_ENABLE" \
  --output_dir="$RUN_DIR"

echo "[TRAIN] End: $(date -Iseconds)"
