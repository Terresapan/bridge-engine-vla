#!/bin/bash
set -e

echo "🚀 Starting LeRobot Phase 0 Setup..."

# 1. Initialize standard environment with Python 3.12
echo "🐍 Initializing standard virtual environment with Python 3.12..."
python3.12 -m venv --copies .venv

# 2. Source the environment (for the current script's context)
source .venv/bin/activate

# 3. Install LeRobot with MuJoCo extras
echo "📦 Installing lerobot[mujoco]..."
uv pip install "lerobot[mujoco]"

# 4. Success message
echo "✅ Setup complete! Use 'source .venv/bin/activate' to start working."
echo "Running basic info check..."
uv run lerobot-info
