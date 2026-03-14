#!/bin/bash
#SBATCH --job-name=bridge-engine-package
#SBATCH --partition=priority
#SBATCH --nodes=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=00:30:00
#SBATCH --output=logs/slurm/%x-%j.out
#SBATCH --error=logs/slurm/%x-%j.err

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

source scripts/slurm/run.env

mkdir -p logs/slurm

RUN_DIR=${RUN_DIR:-"${OUTPUT_ROOT}/${RUN_NAME}"}
if [[ ! -d "$RUN_DIR" ]]; then
  echo "[PKG] Run directory not found: $RUN_DIR"
  exit 1
fi

ART_DIR="$RUN_DIR/artifacts"
mkdir -p "$ART_DIR"

ARCHIVE="$ART_DIR/${RUN_NAME}_bundle_$(date +%Y%m%d_%H%M%S).tar.gz"

TAR_INPUTS=()
[[ -d "$RUN_DIR/checkpoints" ]] && TAR_INPUTS+=("$RUN_DIR/checkpoints")
[[ -f "$RUN_DIR/validation_manifest.json" ]] && TAR_INPUTS+=("$RUN_DIR/validation_manifest.json")
[[ -d "$REPO_ROOT/logs/slurm" ]] && TAR_INPUTS+=("$REPO_ROOT/logs/slurm")

if [[ ${#TAR_INPUTS[@]} -eq 0 ]]; then
  echo "[PKG] Nothing to package."
  exit 1
fi

tar -czf "$ARCHIVE" "${TAR_INPUTS[@]}"
sha256sum "$ARCHIVE" > "$ARCHIVE.sha256"

cat <<EOF
[PKG] Host: $(hostname)
[PKG] Run dir: $RUN_DIR
[PKG] Archive: $ARCHIVE
[PKG] Checksum: $ARCHIVE.sha256
[PKG] End: $(date -Iseconds)
EOF
