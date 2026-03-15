# Bridge Engine Hackathon Execution Plan (Next 5 Hours)

This plan is optimized for your current reality:
- training is running now on 8 GPUs,
- full training likely will not finish in the next 5 hours,
- you still need simulation videos and a presentation.

Goal: deliver the **best possible demo assets** before deadline, while training continues in parallel.

---

## 0) Ground Rules (Read First)

1. Do **not** wait for full 120k-step completion before doing simulation.
2. Use the latest usable checkpoint every cycle (e.g. `025000`, `030000`, ...).
3. Keep one process for monitoring training and one process for eval/video generation.
4. Freeze a final demo checkpoint at T-2h, even if newer checkpoints are still training.
5. Keep all simulation and rendering on the remote GPU cluster, not local Mac.

---

## 1) Time-Boxed Schedule (5 Hours)

## T-5:00 to T-4:30 (Setup + First Eval)

- Confirm training job status and remaining time.
- Identify latest checkpoint.
- Run first evaluation pass and generate first video.
- Create a simple score sheet (`checkpoint -> success/fail notes`).

## T-4:30 to T-3:00 (Checkpoint Sweep)

- Every time a new checkpoint appears, run eval + video export.
- Compare against previous best.
- Keep top 2 candidate checkpoints.

## T-3:00 to T-2:00 (Stabilize + Select Best)

- Run a slightly longer eval on top 2 checkpoints.
- Choose one “primary demo checkpoint” and one backup.
- Start drafting slides with available evidence.

## T-2:00 to T-1:00 (Asset Finalization)

- Freeze demo assets:
  - selected checkpoint metadata,
  - best videos,
  - run status screenshots,
  - brief metrics table.
- Start packaging artifacts.

## T-1:00 to T-0:00 (Presentation Build + Dry Run)

- Finalize slide story: problem -> approach -> training status -> sim results -> next steps.
- Verify all media links and local copies.
- Do one full dry-run of talk track.

---

## 2) Commands You Will Use Repeatedly

> Run these from your login node (`user29@35.84.33.219`) unless noted.

## 2.1 Monitor training

```bash
squeue -j 570 -o '%i %T %M %l %L %R'
tail -f ~/bridge-engine-vla/logs/slurm/bridge-engine-train-570.out
tail -f ~/bridge-engine-vla/logs/slurm/bridge-engine-train-570.err
```

## 2.2 Find latest checkpoint

```bash
RUN_DIR=/mnt/sharefs/user29/bridge_engine_runs/trinity_smolvla_20260315_024136
ls -1 "$RUN_DIR/checkpoints" | sort
```

Expected checkpoint path format:

```bash
$RUN_DIR/checkpoints/025000/pretrained_model
$RUN_DIR/checkpoints/030000/pretrained_model
...
$RUN_DIR/checkpoints/last/pretrained_model
```

## 2.3 Run evaluation from a checkpoint

Use your LeRobot eval command template (replace env/task args as needed):

```bash
CHECKPOINT_DIR="$RUN_DIR/checkpoints/025000/pretrained_model"

lerobot-eval \
  --policy.path="$CHECKPOINT_DIR" \
  --output-dir="$RUN_DIR/eval/025000" \
  --num-episodes=20
```

If video export is available via eval flags in your setup, add them (example pattern):

```bash
  --save-video=true \
  --video-dir="$RUN_DIR/eval/025000/videos"
```

## 2.4 Keep a simple checkpoint score table

Create and update manually in markdown:

```text
Checkpoint | Episodes | Success Rate | Qualitative Notes | Video Path
025000     | 20       | TBD          | TBD               | ...
030000     | 20       | TBD          | TBD               | ...
```

---

## 3) Strategy Decisions (Important)

## Q1: Should we use partial checkpoints now?

**Yes.** Use partial checkpoints immediately for simulation and video while full training continues.
This is the best deadline strategy.

## Q2: Do we need to download model to local Mac for simulation?

**No.** Do not run simulation locally on Mac Mini 16GB for this workflow.
Run eval/render on cluster GPUs, then download only resulting artifacts (videos, logs, images).

## Q3: No W&B — how to estimate quality?

Use checkpoint-to-checkpoint eval comparisons:
- fixed eval settings,
- same episode count,
- compare success rates and failure modes,
- choose best qualitative video for presentation.

---

## 4) Artifact Checklist for Presentation

By T-1h, ensure you have:

- [ ] Best checkpoint path documented.
- [ ] 2-4 short simulation clips (`.mp4`) showing success and recovery.
- [ ] One table of checkpoint comparisons.
- [ ] One screenshot of training job status (`squeue`/`scontrol`).
- [ ] One slide with current limitations + next-step plan.

Suggested narrative:
1. Why Trinity blend (nav + sorting + grasping)
2. Why mixed-DoF strategy
3. Live training status under deadline constraints
4. Best simulation evidence from intermediate checkpoints
5. What full run + resume will improve next

---

## 5) Contingency Plan (If Training Stops Early)

If `bridge-engine-train` hits walltime before completion:

1. Keep best checkpoint for demo (no delay).
2. Resume training after demo using:

```bash
export RESUME=true
export RESUME_RUN_DIR=/mnt/sharefs/user29/bridge_engine_runs/trinity_smolvla_20260315_024136
export RESUME_CHECKPOINT=last
bash ~/bridge-engine-vla/scripts/slurm/submit_pipeline.sh
```

3. Continue checkpoint sweep on resumed run for post-demo results.

---

## 6) Step-by-Step Working Mode (How We Collaborate)

We will run this together in this order:

1. Confirm latest checkpoint available now.
2. Launch eval for that checkpoint.
3. Capture result + video path.
4. Repeat for the next checkpoint.
5. Decide primary + backup checkpoint.
6. Freeze assets and build final presentation.

When you are ready, start with this and paste output:

```bash
RUN_DIR=/mnt/sharefs/user29/bridge_engine_runs/trinity_smolvla_20260315_024136
ls -1 "$RUN_DIR/checkpoints" | sort
```
