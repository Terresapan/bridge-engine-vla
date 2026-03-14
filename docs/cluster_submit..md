# Submitting Jobs
Login nodes are for editing code and submitting jobs — do not run GPU workloads directly on login nodes.
Interactive Session (Quick Testing)

Grab a single GPU interactively:
srun --gpus=1 --pty 

Request specific resources:
srun --gpus=4 --cpus-per-gpu=16 --mem=128G --time=01:00:00 --pty

Interactive Allocation (Multi-Step Work)

salloc --gpus=2 --time=02:00:00
# You now have an allocation — run commands against it:
srun python train.py
# When done:
exit

Batch Job (Long-Running / Unattended). Create a job script, e.g. train.sh:
#!/bin/bash
#SBATCH --job-name=my-training
#SBATCH --gpus=4
#SBATCH --cpus-per-gpu=16
#SBATCH --mem=256G
#SBATCH --time=04:00:00
#SBATCH --output=logs/%x-%j.out
#SBATCH --error=logs/%x-%j.err

# Make sure log directory exists
mkdir -p logs

# Your workload
python train.py --config config.yaml



## Submit it:
sbatch train.sh 

## Etiquette & Fair Usage
Be mindful of others. 30 participants share 32 GPU nodes. Don't hog resources you aren't actively using.
Set --time limits on all jobs. If your job finishes early, resources free up for others. If you forget, a runaway job blocks everyone.
Cancel idle allocations. If you salloc a node and walk away, scancel it.
Use --output and --error flags for batch jobs so you can debug without re-running.
Shared Storage
Your home directory (/home/<username>) lives on a 61 TB shared Lustre filesystem (/mnt/sharefs). This means:
Files you create on any login node are immediately visible on every compute node (and vice versa).
No need to copy data between nodes — just reference paths normally.
Be considerate with storage — 61 TB is shared across all participants. Clean up large intermediate files when you're done.

## Important: Cluster Guidelines
A few ground rules to keep things running smoothly for everyone:

## Do NOT:
Modify or unmount the shared filesystem (/fsx). If it goes down, it goes down for all 232 of you and we cannot get it restored quickly.
Change networking or security group settings in the AWS console. The EFA fabric connecting the nodes is fragile — one misconfiguration takes down inter-node communication for every team.
Stop, terminate, or reboot instances. These are shared resources on reserved capacity — if an instance goes down, we cannot replace it.
Install kernel modules or update NVIDIA drivers. The driver, CUDA, and EFA stack are pinned to specific versions. Updating any of them can break GPU and network functionality for the node.
Run sudo commands that modify system services (systemd, Slurm, munge, networking).
Attempt to access other teams' directories or jobs.

## Do:
Use your allocated Slurm partition and GPU quota for all jobs.
Write your data to your designated directory on /fsx.
Use local NVMe scratch space (/tmp or /local_scratch) for temporary files — it's fast and doesn't impact other users.
Let us know in Discord if something seems broken — don't try to fix infrastructure yourself.
