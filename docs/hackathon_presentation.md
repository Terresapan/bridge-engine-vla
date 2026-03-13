# Hackathon Scope: Bridge Engine VLA Foundation Model

## The Problem
Training a logistics robot from scratch using only private trailer data takes too long and requires too much expensive data collection. 

## The Hackathon Solution: "Multi-Dataset Blending"
Instead of training a narrow model to do one thing, we will use the massive Fluidstack GPU compute to train a **Vision-Language-Action (VLA)** foundation model. We will blend multiple open-source datasets (picking, sorting, navigating) together.

By the end of the weekend, we will have a single "Base Brain" that understands:
1. 3D spatial geometry and object boundaries.
2. How to grasp irregular items.
3. How to follow basic language commands ("Sort the box").

When it is time for the real-world deployment (Phase 2), we simply "fine-tune" this massive Base Brain on a tiny amount of real trailer data, achieving reliability in hours instead of months.

## Proposed Datasets for Blending
We searched the Hugging Face `lerobot` repository for high-quality datasets that match our chaotic trailer use case. Crucially, **no narrow pre-built models exist for these specific combinations**, meaning our hackathon output will be a net-new asset.

## Why these 3 Datasets?
Our goal is to build a "Moving-Sorting-Unloader." We are blending these three because they form the **"Trinity"** of pillar skills Morgan's robot needs:
1.  **Grasping Skill**: `lerobot/svla_so100_pickplace` (Raw physics of the hand - grasping objects from chaotic piles).
2.  **Categorization Skill**: `lerobot/svla_so100_sorting` (The brain deciding where different types of freight should go).
3.  **Navigation Skill**: `lerobot/aloha_mobile_cabinet` (The legs/wheels moving the robot while the arm remains active).

### The Multi-Embodiment Opportunity
Morgan's team needs to know: **Can we actually blend datasets that have different camera names and counts?**
**Yes, we can.** This is the exact frontier of VLA models (Vision-Language-Action).
*   **ACT (Legacy):** Would crash because the tensor shapes don't align (2 cams vs 3).
*   **VLA (Modern, e.g., Pi0):** Tokenizes images independently. This makes our foundation model robust to whatever camera setup Morgan eventually builds!

### "Silent" VLA: Why Language matters for a Quiet Robot
Even if Morgan wants the robot to empty trailers autonomously without any "voice conversation," training a VLA model is still the winning move:
*   **Concept Intelligence:** By training with language labels (e.g., "pick up box"), the robot learns to recognize "Box-ness" as a category. A Vision-Only model just learns specific pixel patterns.
*   **Result:** The VLA model will handle a weirdly colored or dented box much better than a silent model, because it has linked the visual pixels to the linguistic concept of "Box".

## Capabilities & Limitations
### What this Base Model ENABLES:
1.  **General Physics Mastery:** The robot will understand depth, friction, and gravity.
2.  **Basic Grasping:** It will reliably pick up common industrial objects (cartons, bins).
3.  **High-Level Task Following:** It can switch between "Sorting" and "Unloading" instantly via internal command strings.

### What it CANNOT do yet:
1.  **Proprietary Perfection:** It won't know the exact weight or center-of-gravity of Morgan's specific proprietary shipping cartons.
2.  **Millimeter Precision:** Out-of-the-box accuracy might be ~90% instead of the required 99.9%.

## Phase 2: How Morgan "Fine-Tunes" our Model
Morgan doesn't need a year of data. Once we have the Base Brain from the hackathon, the transfer process is simple:
1.  **Data Capture:** Morgan records ~50-100 demonstrations (about 1-2 hours of video) of a human controlling her specific robot in a real trailer.
2.  **The "Fine-Tune":** We run a quick training session (takes ~30 minutes on a single GPU) where we show the Base Brain this new data.
3.  **Specialization:** The brain says "I already know how to move and grasp, I just need to adjust my precision for this specific trailer."
4.  **Result:** Commercial-grade reliability achieved with minimal data.

## Model Specs & Hackathon Feasibility
We will target a **Vision-Language-Action (VLA)** architecture (likely a **Pi0 variant** or **SmolVLA**) between **1 Billion and 5 Billion parameters**.

*   **The Strategy:** We aren't training a GPT-4 from scratch. We are starting with a **pre-trained brain** (like SigLIP or PaliGemma) and simply **"co-training"** it on our three robotics datasets. 
*   **Feasibility:** On high-end GPUs, we can process millions of frames of robotics data. Within a **36-hour window** on a high-end cluster, this is perfect for producing a high-intelligence **"Hackathon Foundation Model."**

## Infrastructure Request: Fluidstack GPU Clusters
During the 5:00 PM webinar, you should make a clear, technical request for **High-Interconnect Multi-Node Compute**. Based on their fleet, here is what we need:

*   **Primary Request:** 1x Node with **8x NVIDIA H100 (80GB)** GPUs. 
*   **Networking Requirements:** Must have **InfiniBand Interconnect** (Fluidstack clusters support up to 3.2 Tb/s). This ensures the 8 GPUs can talk to each other fast enough to train the foundation model.
*   **Alternative:** 1x Node with **8x NVIDIA A100 (80GB)** GPUs. (Slower than H100, but still very capable for our data size).

> [!NOTE]
> Even though H100s are expensive, they are standard "prize" inventory for Fluidstack hackathons. Providing one 8-GPU node for 48 hours is a very common sponsorship level. 


## Key Decisions Needed from Morgan
1. **Camera Architecture:** Where will the cameras be mounted on the actual physical robot? (e.g., On the wrist? Overhead mast?). **Why this matters:** Even though we are blending 3 prebuilt datasets, we need to make sure the datasets we chose have camera angles that match Morgan's actual robot. If Morgan's robot only has a wrist camera, but our 3 datasets only use overhead cameras, the model won't translate well. We may need to swap one of the datasets out if her camera setup is unique!
2. **Success Metrics:** What defines a successful pilot? (E.g., 99% pick success, or 500 cartons per hour?) This will determine our training loss function.
3. **Language Interface:** Does the robot need to follow text/voice commands?
    *   **Decision:** We are choosing VLA to gain its superior intelligence, regardless of whether a microphone is installed. We deploy it "silently".

## Real-World VLA Use Case: On-Site at the Warehouse
Morgan's team might ask: "Who is going to be talking to the robot?" 
The answer is: **Probably no one, most of the time.** 

Instead, the VLA "Language" layer acts as a **Global Remote Control**:
1.  **Zero-Shot Generalization:** When a totally new piece of freight appears that the robot has never seen, the VLA model uses its language-trained brain to "guess" how to handle it correctly without needing a software update.
2.  **Easy Exception Handling:** If a box spills, a warehouse worker can simply type/say "Clear the debris" on a tablet. Without VLA, you would need a specialized robotics engineer to write new code for that specific spill.
3.  **Dynamic Task Switching:** Morgan can repurpose the trailer-unloader to "Clean the floor" or "Sort pallets" just by changing the command string in the software, rather than retraining the model from scratch.
