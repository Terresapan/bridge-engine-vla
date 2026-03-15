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

REPO_ROOT="${SLURM_SUBMIT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
cd "$REPO_ROOT"

source scripts/slurm/run.env

mkdir -p logs/slurm
mkdir -p "$OUTPUT_ROOT"

export HF_HOME
export TMPDIR
export HF_HUB_ENABLE_HF_TRANSFER=1

if [[ "${RESUME,,}" == "true" ]]; then
  if [[ -z "${RESUME_RUN_DIR}" ]]; then
    echo "[TRAIN] RESUME=true requires RESUME_RUN_DIR"
    exit 1
  fi
  RUN_DIR="${RESUME_RUN_DIR}"
  RUN_NAME="$(basename "$RUN_DIR")"
else
  RUN_DIR="${OUTPUT_ROOT}/${RUN_NAME}"
fi

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

MASTER_ADDR="$(scontrol show hostnames "$SLURM_JOB_NODELIST" | head -n 1)"
MASTER_PORT="${MASTER_PORT:-29500}"
NUM_PROCESSES="${NUM_PROCESSES:-${SLURM_GPUS_ON_NODE:-8}}"
NUM_MACHINES="${SLURM_NNODES:-1}"
MACHINE_RANK="${SLURM_NODEID:-0}"

srun --ntasks=1 --nodes=1 \
  /mnt/sharefs/user29/miniconda3/bin/conda run -n lerobot312 \
  accelerate launch \
    --multi_gpu \
    --num_processes "${NUM_PROCESSES}" \
    --num_machines "${NUM_MACHINES}" \
    --machine_rank "${MACHINE_RANK}" \
    --main_process_ip "${MASTER_ADDR}" \
    --main_process_port "${MASTER_PORT}" \
    scripts/slurm/launch_train.py

echo "[TRAIN] End: $(date -Iseconds)"
