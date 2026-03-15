#!/bin/bash
set -euo pipefail

# Append one evaluation result row to docs/eval_score_sheet.md from eval_info.json
# Usage:
#   bash scripts/slurm/update_score_sheet.sh [CHECKPOINT_TAG] [NOTES]
#
# Environment:
#   RUN_DIR          # optional, falls back to logs/slurm/latest_run_dir.txt or OUTPUT_ROOT/RUN_NAME
#   EVAL_ENV_TYPE    # optional, recorded into the sheet (default: unknown)

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

source scripts/slurm/run.env

# Resolve RUN_DIR
if [[ -n "${RUN_DIR:-}" ]]; then
  RD="$RUN_DIR"
elif [[ -f logs/slurm/latest_run_dir.txt ]]; then
  RD="$(cat logs/slurm/latest_run_dir.txt)"
else
  RD="${OUTPUT_ROOT}/${RUN_NAME}"
fi

if [[ ! -d "$RD" ]]; then
  echo "[SHEET] Run directory not found: $RD"
  exit 1
fi

TAG="${1:-last}"
NOTES="${2:-}"
ENV_NAME="${EVAL_ENV_TYPE:-unknown}"

EVAL_DIR="$RD/eval/$TAG"
INFO_JSON="$EVAL_DIR/eval_info.json"
if [[ ! -f "$INFO_JSON" ]]; then
  echo "[SHEET] Missing eval_info.json at: $INFO_JSON"
  exit 1
fi

# Extract fields with python for robustness
readarray -t FIELDS < <(python3 - <<'PY'
import json, os, sys
from pathlib import Path
run_dir = os.environ['RD']
tag = os.environ['TAG']
eval_dir = Path(run_dir) / 'eval' / tag
info_path = eval_dir / 'eval_info.json'
info = json.loads(info_path.read_text())
ov = info.get('overall', {})
print(tag)
print(ov.get('n_episodes', ''))
print(f"{ov.get('pc_success', float('nan')):.2f}")
print(f"{ov.get('avg_sum_reward', float('nan')):.3f}")
# pick first video path if available
vps = ov.get('video_paths', [])
print(vps[0] if vps else '')
PY
)

CHKPT_TAG="${FIELDS[0]:-}"
N_EPS="${FIELDS[1]:-}"
PC_SUCCESS="${FIELDS[2]:-}"
AVG_REWARD="${FIELDS[3]:-}"
VIDEO_PATH="${FIELDS[4]:-}"

SHEET="docs/eval_score_sheet.md"
if [[ ! -f "$SHEET" ]]; then
  cat > "$SHEET" <<'HDR'
# Evaluation Score Sheet

| Checkpoint | Episodes | Success % | Avg Sum Reward | Env | Video (first) | Notes |
|-----------:|---------:|----------:|---------------:|:----|:--------------|:------|
HDR
fi

echo "| ${CHKPT_TAG} | ${N_EPS} | ${PC_SUCCESS} | ${AVG_REWARD} | ${ENV_NAME} | ${VIDEO_PATH} | ${NOTES} |" >> "$SHEET"

echo "[SHEET] Appended row to $SHEET"
