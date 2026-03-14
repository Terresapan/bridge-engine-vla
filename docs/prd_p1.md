# Bridge Engine Phase 1: Hackathon PRD
**Objective:** Train a Vision-Language-Action (VLA) foundation model capable of generalized grasping, sorting, and navigation, using Multi-Dataset Blending.
**Timeline:** 36-48 Hours (Weekend Hackathon)
**Target Hardware:** 1x A100 or H100 GPU (Funded by $250 Hacker Credit)

---

## 1. Datasets & Blending Strategy
We will construct a `MultiLeRobotDataset` to teach the "Trinity of Skills".

### 1.1 The Source Datasets & Sampling Weights
Using a Weighted Sampler, we will balance the training batches:
1.  **Navigation (50%):** `lerobot/aloha_mobile_cabinet` (The "Moving" base logic)
2.  **Categorization (30%):** `lerobot/svla_so100_sorting` (The "Sorting" logic)
3.  **Grasping (20%):** `lerobot/svla_so100_pickplace` (The "Unloader" precision)

### 1.2 The Technical Integration Matrix
Blending these datasets requires solving specific structural mismatches:
*   **DoF Alignment (14 vs 6 Motors):** We will pad the SO100 action vectors with zeros to match Aloha's 14 dimensions. During backpropagation on SO100 frames, we will mask the loss on the "missing" dimensions (wheels/second arm) so the network only updates the primary arm weights.
*   **Time Alignment (50 FPS vs 30 FPS):** We will use LeRobot's built-in resampling to downsample the Aloha data from 50Hz to 30Hz to match the SO100 datasets, standardizing the network's perception of time.
*   **Camera Alignment (3 vs 2 Cameras):** The `wrist` camera in the SO100 datasets will be explicitly mapped to the `cam_right_wrist` in the Aloha dataset, teaching the model a unified concept of a "precision view."

---

## 2. Model Architecture: 2.2B VLA (The "Goldilocks" Size)
We have selected a **2.2B parameter VLA architecture** (like a SmolVLM2-2.2B backbone variant).

### 2.1 Why 2.2B Parameters?
*   **The Intelligence Floor:** A 450M model struggles with the complex "decision making" and semantic reasoning required for the Sorting task. The 1.7B LLM backbone inside a 2.2B model is significantly better at instruction following (e.g., "Place the red block in the blue bin").
*   **The Overfitting Ceiling:** Models in the 7B-10B range are too large for our combined frame count (~180k frames). They would memorize the exact pixel backgrounds of the specific videos rather than generalizing the physics of movement. 2.2B is the exact sweet spot for our data volume.

### 2.2 Co-Training Definition
"Co-Training" means we are taking the pre-trained LLM backbone and training the robot's motor-control layers while simultaneously keeping the vision layers "awake." This allows the model to map specific pixels directly to the 14-dimensional motor torques.

---

## 3. Training Infrastructure: Fluidstack Multi-Node Compute
Training a 2.2B parameter VLA requires maximum optimization on distributed compute.

### 3.1 Fluidstack Node Specs
Our primary request to the hackathon organizers is:
*   **Compute:** 1x Node with 8x NVIDIA H100 (80GB) GPUs.
*   **Fabric:** InfiniBand interconnect is mandatory.

### 3.2 H100 Optimization Strategy (`lerobot-train`)
To maximize our Token-per-Second throughput on the H100s, we will use advanced parallelization:
*   **FSDP (Fully Sharded Data Parallel):** We will use FSDP instead of standard DDP to slice the model weights across the 8 GPUs efficiently.
*   **Precision:** Use **FP8** arithmetic (via Transformer Engine) to double throughput.
*   **Massive Batching:** We will set `batch_size=128` per GPU (Total Batch Size of **1024**). This massive batch size smooths the gradient and improves generalization.
*   **Result:** This optimization allows us to run a full 2.2B training loop in **under 6 hours**, granting us the time to run 3 full iterative A/B testing cycles during the weekend.

---

## 4. Evaluation & Deliverables
By Sunday evening, the team must produce three artifacts to prove success.

### 4.1 Deliverable 1: The Model Checkpoint
*   **What:** The serialized model weights (`model.safetensors`).
*   **Where:** Pushed dynamically to a designated Hugging Face organization (`${HF_USER}/bridge-engine-vla-v1`).

### 4.2 Deliverable 2: Simulation Benchmark (MuJoCo)
We will use **MuJoCo** as our primary simulation environment.
*   **Why MuJoCo?** It is natively integrated into LeRobot's evaluation pipeline (`lerobot-eval`). While Isaac Lab offers higher fidelity, MuJoCo's faster-than-real-time physics allows us to test 100+ episodes in minutes.
*   **Action:** Run `--eval_freq=1000` during training to monitor success rate live.
*   **Metric:** Achieve >85% success rate on chaotic grasping and sorting tasks.

### 4.3 Deliverable 3: The "Showcase Website"
A dedicated GitHub Pages or Vercel static site to present to Morgan and stakeholders.
*   **Content:**
    1.  **The "Trinity" Explanation:** Why we blended those 3 datasets.
    2.  **Training Curves:** Embedded Weights & Biases charts proving convergence.
    3.  **Simulation Videos:** The screen-recorded `mp4` outputs from `lerobot-eval` showing the robot successfully executing the tasks in a 3D environment. 
    4.  **Hardware Roadmap:** Link to our Phase 2/3 hardware integration plan.

---

## 5. Hackathon Execution Timeline: The 3-Run Strategy
Because our FSDP/FP8 optimizations allow a full training run in under 6 hours on the H100s, we will execute three distinct runs:
*   **Friday 8 PM - Midnight:** Environment setup, Data Resampling/Alignment, and merging the dataset.
*   **Saturday AM (Run 1 - Baseline):** First 6-hour training run. Monitor convergence on W&B and run MuJoCo Benchmark.
*   **Saturday PM (Run 2 - Adjustment):** Adjust sampler weights (e.g., increase Nav weight if drifting occurs) and run the second 6-hour training loop.
*   **Sunday AM (Run 3 - Clean Deployment):** Final, fully-tuned 6-hour run. Capture Evaluation videos across all 3 benchmark tasks.
*   **Sunday PM:** Build the "Showcase Website" with the A/B testing story and present to Morgan.
