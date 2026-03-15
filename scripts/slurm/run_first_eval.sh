#!/bin/bash
set -euo pipefail

# Wrapper to launch a 1xGPU eval job against a specific checkpoint and save videos.
# Usage:
#   bash scripts/slurm/run_first_eval.sh [CHECKPOINT_TAG]
#
# Env overrides (optional):
#   EVAL_ENV_TYPE   # e.g., libero | metaworld | aloha | pusht (defaults to libero)
#   EVAL_BATCH_SIZE # default: 4
#   EVAL_N_EPISODES # default: 20
#
# Notes:
# - Runs evaluation on the cluster via sbatch using scripts/slurm/eval_and_validate.sh
# - Videos + eval_info.json are saved under: $RUN_DIR/eval/<checkpoint_tag>/

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

source scripts/slurm/run.env
mkdir -p logs/slurm

# Resolve RUN_DIR
if [[ -n "${RUN_DIR:-}" ]]; then
  RD="$RUN_DIR"
elif [[ -f logs/slurm/latest_run_dir.txt ]]; then
  RD="$(cat logs/slurm/latest_run_dir.txt)"
else
  RD="${OUTPUT_ROOT}/${RUN_NAME}"
fi

if [[ ! -d "$RD" ]]; then
  echo "[EVAL] Run directory not found: $RD"
  exit 1
fi

CHECKPOINT_TAG="${1:-last}"
CKPT_DIR=""

# Prefer explicit tag directory with pretrained_model
if [[ -d "$RD/checkpoints/$CHECKPOINT_TAG/pretrained_model" ]]; then
  CKPT_DIR="$RD/checkpoints/$CHECKPOINT_TAG/pretrained_model"
elif [[ -d "$RD/checkpoints/$CHECKPOINT_TAG" ]]; then
  CKPT_DIR="$RD/checkpoints/$CHECKPOINT_TAG"
fi

# If tag is 'last' but structure not present yet, fallback to latest numeric
if [[ -z "$CKPT_DIR" && "$CHECKPOINT_TAG" == "last" ]]; then
  latest_tag="$(ls -1 "$RD/checkpoints" 2>/dev/null | grep -E '^[0-9]+$' | sort -n | tail -n 1 || true)"
  if [[ -n "$latest_tag" && -d "$RD/checkpoints/$latest_tag/pretrained_model" ]]; then
    CHECKPOINT_TAG="$latest_tag"
    CKPT_DIR="$RD/checkpoints/$latest_tag/pretrained_model"
  fi
fi

# Validate checkpoint has weights
if [[ -z "$CKPT_DIR" || ! -f "$CKPT_DIR/model.safetensors" ]]; then
  echo "[EVAL] Could not locate model.safetensors for tag '$CHECKPOINT_TAG' under $RD"
  exit 1
fi

EVAL_ENV_TYPE="${EVAL_ENV_TYPE:-libero}"
EVAL_BATCH_SIZE="${EVAL_BATCH_SIZE:-4}"
EVAL_N_EPISODES="${EVAL_N_EPISODES:-20}"

EVAL_OUTPUT_DIR="$RD/eval/$CHECKPOINT_TAG"
mkdir -p "$EVAL_OUTPUT_DIR"

# Build the eval command (executed inside eval_and_validate.sh via EVAL_COMMAND)
# We use the same conda env as training for maximum compatibility.
EVAL_CMD="/mnt/sharefs/$USER/miniconda3/bin/conda run -n lerobot312 \
python -m lerobot.scripts.lerobot_eval \
  --policy.path=\"$CKPT_DIR\" \
  --env.type=\"$EVAL_ENV_TYPE\" \
  --eval.batch_size=$EVAL_BATCH_SIZE \
  --eval.n_episodes=$EVAL_N_EPISODES \
  --policy.use_amp=true \
  --policy.device=cuda \
  --output_dir=\"$EVAL_OUTPUT_DIR\""

export EVAL_COMMAND="$EVAL_CMD"

jid_eval=$(sbatch --export=ALL,RUN_DIR="$RD" scripts/slurm/eval_and_validate.sh | awk '{print $4}')

cat <<EOF
[EVAL] Submitted eval job: $jid_eval
[EVAL] Run dir: $RD
[EVAL] Checkpoint tag: $CHECKPOINT_TAG
[EVAL] Checkpoint dir: $CKPT_DIR
[EVAL] Output dir: $EVAL_OUTPUT_DIR

Logs:
  tail -f logs/slurm/bridge-engine-eval-$jid_eval.out
  tail -f logs/slurm/bridge-engine-eval-$jid_eval.err
EOF
