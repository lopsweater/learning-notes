#!/bin/bash

# Claude Task Runner - Development Setup Script

set -e

echo "================================"
echo "Claude Task Runner - Setup"
echo "================================"

# Check Python
if ! command -v python3 &> /dev/null; then
    echo "Error: Python 3 is required"
    exit 1
fi

# Check pip
if ! command -v pip &> /dev/null; then
    echo "Error: pip is required"
    exit 1
fi

# Create virtual environment
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
echo "Activating virtual environment..."
source venv/bin/activate

# Install dependencies
echo "Installing dependencies..."
pip install -r backend/requirements.txt

# Create data directory
mkdir -p data

# Check Claude Code
echo ""
echo "Checking Claude Code installation..."
if command -v claude &> /dev/null; then
    echo "✓ Claude Code found: $(which claude)"
else
    echo "⚠ Claude Code not found in PATH"
    echo "  Please install Claude Code: https://docs.anthropic.com/claude/docs/claude-code"
fi

echo ""
echo "================================"
echo "Setup complete!"
echo "================================"
echo ""
echo "To start the server:"
echo "  ./run.sh"
echo ""
echo "Or manually:"
echo "  source venv/bin/activate"
echo "  uvicorn backend.main:app --host 0.0.0.0 --port 3000 --reload"
echo ""
