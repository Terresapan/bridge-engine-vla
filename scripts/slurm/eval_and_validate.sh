#!/bin/bash
#SBATCH --job-name=bridge-engine-eval
#SBATCH --partition=priority
#SBATCH --nodes=1
#SBATCH --gpus=1
#SBATCH --cpus-per-gpu=8
#SBATCH --mem=64G
#SBATCH --time=02:00:00
#SBATCH --output=logs/slurm/%x-%j.out
#SBATCH --error=logs/slurm/%x-%j.err

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

source scripts/slurm/run.env

mkdir -p logs/slurm

RUN_DIR=${RUN_DIR:-"${OUTPUT_ROOT}/${RUN_NAME}"}
if [[ ! -d "$RUN_DIR" ]]; then
  echo "[EVAL] Run directory not found: $RUN_DIR"
  exit 1
fi

CHECKPOINT_DIR=""
if [[ -d "$RUN_DIR/checkpoints/last/pretrained_model" ]]; then
  CHECKPOINT_DIR="$RUN_DIR/checkpoints/last/pretrained_model"
elif [[ -d "$RUN_DIR/checkpoints/last" ]]; then
  CHECKPOINT_DIR="$RUN_DIR/checkpoints/last"
else
  CHECKPOINT_DIR="$(find "$RUN_DIR" -type f -name 'model.safetensors' | head -n 1 | xargs -I{} dirname {})"
fi

if [[ -z "$CHECKPOINT_DIR" || ! -d "$CHECKPOINT_DIR" ]]; then
  echo "[EVAL] Could not locate checkpoint directory under $RUN_DIR"
  exit 1
fi

if [[ ! -f "$CHECKPOINT_DIR/model.safetensors" ]]; then
  echo "[EVAL] Missing model.safetensors in $CHECKPOINT_DIR"
  exit 1
fi

echo "[EVAL] Host: $(hostname)"
echo "[EVAL] Start: $(date -Iseconds)"
echo "[EVAL] Run dir: $RUN_DIR"
echo "[EVAL] Checkpoint dir: $CHECKPOINT_DIR"

# Optional env activation (uncomment and customize if needed)
# source /mnt/sharefs/$USER/miniconda3/etc/profile.d/conda.sh
# conda activate lerobot

if [[ -n "${EVAL_COMMAND}" ]]; then
  echo "[EVAL] Running EVAL_COMMAND"
  # shellcheck disable=SC2086
  CHECKPOINT_DIR="$CHECKPOINT_DIR" RUN_DIR="$RUN_DIR" bash -lc "$EVAL_COMMAND"
else
  echo "[EVAL] EVAL_COMMAND not set; running validation-only mode."
fi

python3 - <<'PY'
import json
import os
from pathlib import Path

run_dir = Path(os.environ["RUN_DIR"])
ckpt_dir = Path(os.environ["CHECKPOINT_DIR"])
manifest = {
    "run_dir": str(run_dir),
    "checkpoint_dir": str(ckpt_dir),
    "model_exists": (ckpt_dir / "model.safetensors").exists(),
    "timestamp": __import__("datetime").datetime.utcnow().isoformat() + "Z",
}
manifest_path = run_dir / "validation_manifest.json"
manifest_path.write_text(json.dumps(manifest, indent=2))
print(f"[EVAL] Wrote {manifest_path}")
PY

echo "[EVAL] End: $(date -Iseconds)"
