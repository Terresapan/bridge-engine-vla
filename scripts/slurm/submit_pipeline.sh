#!/bin/bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

source scripts/slurm/run.env
mkdir -p logs/slurm

if [[ "${RESUME,,}" == "true" ]]; then
  if [[ -z "${RESUME_RUN_DIR}" ]]; then
    echo "RESUME=true requires RESUME_RUN_DIR"
    exit 1
  fi
  RUN_DIR="${RESUME_RUN_DIR}"
  RUN_NAME="$(basename "$RUN_DIR")"
else
  RUN_DIR="${OUTPUT_ROOT}/${RUN_NAME}"
fi

jid_train=$(sbatch --export=ALL,RUN_DIR="$RUN_DIR" scripts/slurm/train_main.sh | awk '{print $4}')
jid_eval=$(sbatch --dependency=afterok:${jid_train} --export=ALL,RUN_DIR="$RUN_DIR" scripts/slurm/eval_and_validate.sh | awk '{print $4}')
jid_pkg=$(sbatch --dependency=afterok:${jid_eval} --export=ALL,RUN_DIR="$RUN_DIR" scripts/slurm/package_artifacts.sh | awk '{print $4}')

cat <<EOF
Submitted pipeline:
  train job id:    $jid_train
  eval job id:     $jid_eval
  package job id:  $jid_pkg

Run name: $RUN_NAME
Run dir:  $RUN_DIR

Track with:
  squeue -u $USER
  sacct -j ${jid_train},${jid_eval},${jid_pkg} --format=JobID,JobName,State,Elapsed
EOF
