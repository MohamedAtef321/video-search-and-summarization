#!/bin/bash
# Local Execution Setup Script for VSS Engine (WSL2/Ubuntu)
# This script installs all necessary OS packages and Python dependencies
# to run the VIA Engine natively without Docker.

set -e

echo "=================================================="
echo "Setting up VSS Engine for local execution (WSL2)"
echo "=================================================="

# 1. Update and install system dependencies
echo "[1/4] Installing system dependencies (GStreamer, PyGObject, etc.)..."
sudo apt-get update
sudo apt-get install -y \
    python3-pip \
    python3-venv \
    python3-gi \
    python3-gi-cairo \
    gir1.2-gtk-3.0 \
    python3-gst-1.0 \
    libgirepository1.0-dev \
    libcairo2-dev \
    gstreamer1.0-plugins-bad \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-libav \
    gstreamer1.0-tools \
    ffmpeg

# 2. Create and activate a virtual environment
echo "[2/4] Setting up Python virtual environment..."
if [ ! -d "vss_env" ]; then
    python3 -m venv vss_env
fi
source vss_env/bin/activate

# 3. Install required Python packages
echo "[3/4] Installing Python dependencies..."
# Core dependencies derived from via_server.py/via_demo_client.py
pip install --upgrade pip
pip install fastapi \
    uvicorn \
    aiofiles \
    prometheus_client \
    pydantic \
    pydantic-settings \
    sse_starlette \
    aiohttp \
    gradio \
    PyYAML \
    pyaml-env \
    python-multipart

# Note: The original Dockerfile also installs context-aware-rag dependencies, 
# but they are very large and complex to build natively (cuml, cugraph).
# Since you use the API-based mode and CA_RAG is usually disabled by default,
# we are skipping them to keep the installation lean.

echo "[4/4] Environment setup complete."
echo "=================================================="
echo "To run the VIA Server locally:"
echo "1. Activate the environment: source vss_env/bin/activate"
echo "2. Navigate to the source code: cd src/vss-engine"
echo "3. Run via_server: python3 src/via_server.py --port 8000 --model-path ./dummy --num-gpus 0 --vlm-model-type openai-compat"
echo "=================================================="
