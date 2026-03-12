# PRD: Bridge Engine Phase 0 (Digital-First)

## 1. Project Overview
**Phase 0** is the technical foundation for the Bridge Engine trailer unloading MVP. The goal is to prove the AI-driven approach using the **LeRobot** framework in a 100% digital environment (simulation) before investing in physical hardware.

## 2. Objectives
- **Feasibility Proof**: Demonstrate that a LeRobot policy can reliably identify and manipulate boxes in a simulated "chaotic" environment.
- **Workflow Validation**: Establish a stable data pipeline: Hugging Face (Data) → Google Colab (Training) → Local Mac (Simulation Inference).
- **Skill Building**: Develop core expertise in LeRobot's `Robot` interface and `LeRobotDataset` manipulation.

## 3. Target MVP Scenario (Digital)
- **Environment**: A virtual 53ft trailer with diverse floor-loaded boxes (MuJoCo or Isaac Lab).
- **Robot**: A simulated generic high-payload robotic arm mounted on a mobile base.
- **Task**: Successfully pick a box from a pile and place it onto a simulated conveyor belt.

## 4. Technical Requirements
- **Framework**: LeRobot (PyTorch-based).
- **Simulation**: MuJoCo (Primary/Lightweight) or NVIDIA Isaac Lab (Advanced).
- **Data**: Borrowed datasets from Hugging Face Hub (e.g., Aloha or pick-place datasets).
- **Computing**: 
  - **Local**: Mac mini M2 (8GB) for code development and simulation visualization.
  - **Cloud**: Google Colab (GPU) for training the neural network policies.

## 5. Phase 0 Milestones
1.  **Step 1: Environment Setup**: Install LeRobot locally and run a basic MuJoCo simulation scene.
2.  **Step 2: Data Exploration**: Pull and visualize an existing robotics dataset to understand the "Action/State" schema.
3.  **Step 3: Training Proof**: Train a simple policy in Colab using public data and export the model.
4.  **Step 4: Virtual Success**: Run the trained model in the local simulation and record a successful autonomous "pick."

## 6. Success Metrics
- **0% Hardware Cost**: Accomplish a successful pick/place cycle without physical robots.
- **Autonomous Inference**: The robot makes its own decisions in simulation based on visual input.
- **Repeatable Pipeline**: Documented steps to move from training to simulation in under 15 minutes.
