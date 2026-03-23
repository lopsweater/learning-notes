#!/bin/bash

# Claude Task Runner - Startup Script

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Check Python
if ! command -v python3 &> /dev/null; then
    echo "Error: Python 3 is required"
    exit 1
fi

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
source venv/bin/activate

# Install dependencies
echo "Installing dependencies..."
pip install -q -r backend/requirements.txt

# Run the server
echo "Starting Claude Task Runner..."
echo "Open http://localhost:${PORT:-3000} in your browser"
echo ""

# Set config path if not set
export CLAUDE_TASK_RUNNER_CONFIG="${CLAUDE_TASK_RUNNER_CONFIG:-$SCRIPT_DIR/config.yaml}"

# Run uvicorn
exec uvicorn backend.main:app \
    --host "${HOST:-0.0.0.0}" \
    --port "${PORT:-3000}" \
    --reload \
    --reload-dir backend \
    --reload-dir frontend
