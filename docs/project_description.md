# Bridge Engine VLA — Project Description (Hackathon Draft)

## 1) Goal
- Build a Vision-Language-Action (VLA) policy that performs Aloha insertion reliably under strict time/compute limits.
- Demonstrate a fast training/evaluation loop for multi-dataset blended robotics learning that can yield presentable rollouts in hours, not days.
- Deliverables:
  - Trained checkpoint(s) with basic metrics.
  - Short simulation videos for the presentation.
  - Clear, reproducible pipeline (Slurm + scripts) for training and evaluation.

## 2) Framework and Repo Strategy
- Frameworks/stack:
  - LeRobot (policy/env/tooling), PyTorch, Gym-Aloha, MuJoCo (EGL headless rendering), Accelerate for DDP.
  - Policy: `smolvla` (14-DoF) with mask-aware processing preserved.
  - Conda environment: `lerobot312`.
- Why clone/vendor the source repo:
  - Pin exact versions and avoid pip drift during a time-boxed hackathon.
  - Integrate minimal Slurm-first glue (submit/launch/eval scripts) and keep configs/docs/artifacts in one place for reproducibility.
  - Move fast on environment-specific issues:
    - Headless rendering via `MUJOCO_GL=egl`, `PYOPENGL_PLATFORM=egl`.
    - Stable `rename_map` delivery (wrapper script) to align env observation keys with policy inputs without Slurm/JSON quoting pitfalls.

## 3) Training Process and Current Status (~25%)
- Target steps: `120000` (see `scripts/slurm/run.env`).
- Mixed-dataset plan aligned with PRD (navigation/categorization/grasping) with consistent DoF padding/masks; compatibility preserved when masks are missing.
- Launch: `scripts/slurm/train_main.sh` uses `accelerate` via `scripts/slurm/launch_train.py`.
- Status:
  - Training timed out at walltime; last stable checkpoint at `030000` steps (~25% of target).
  - Run dir: `/mnt/sharefs/user29/bridge_engine_runs/trinity_smolvla_20260315_024136`.
  - Saved checkpoints: `005000, 010000, 015000, 020000, 025000, 030000` (`last -> 030000`).

## 4) Evaluation and Simulation
- TBD — will be filled after the current evaluation job completes (metrics and first video path).

## 5) Key Engineering Decisions
- Minimal, targeted changes per project guardrails; no broad refactors in core training/eval logic.
- Headless rendering fixed via EGL to enable video export on the cluster.
- `rename_map` passed via a remote wrapper script to avoid JSON quoting issues through `sbatch --export`.
- Preference for smoke/short evals to surface a viable demo before committing to longer runs.

## Challenges and Mitigations
- Renderer failures in headless: solved with EGL env vars.
- Quoting/CLI fragility (`rename_map`): solved by embedding exact JSON in a wrapper shell script executed remotely.
- Timeboxed compute: prioritized earlier checkpoint(s) (e.g., `030000`) to guarantee artifacts for the presentation.

## Reproducibility and Artifacts
- Environment: conda `lerobot312`.
- Scripts:
  - Training: `scripts/slurm/train_main.sh`, `scripts/slurm/launch_train.py`, `scripts/slurm/run.env`.
  - Eval: `scripts/slurm/eval_and_validate.sh` and a remote wrapper (with EGL + `rename_map`).
- Outputs:
  - Checkpoints: `$RUN_DIR/checkpoints/<STEP>/pretrained_model`.
  - Eval results: `$RUN_DIR/eval/<TAG>/eval_info.json` and videos under `$RUN_DIR/eval/<TAG>/videos/aloha_0/`.
  - Logs: `~/bridge-engine-vla/logs/slurm/bridge-engine-*.{out,err}`.
  - Local video: `aloha_demo.mp4`,`video/aloha_0_eval_episode_0_030000.mp4` `aloha_0_eval_episode_0.mp4`

