#!/bin/bash
# Local Execution Setup Script for VSS Engine (No-Sudo/User-Level)
# This script installs Python dependencies using 'uv'.
# Note: System-level libraries (GStreamer, FFmpeg, etc.) must be pre-installed by an admin.

set -e

echo "=================================================="
echo "Setting up VSS Engine for local execution (User-Level)"
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
echo "[2/4] Setting up Python virtual environment with uv..."
if ! command -v uv >/dev/null 2>&1; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.cargo/bin:$PATH"
fi

if [ -d "vss_env" ] && [ ! -f "vss_env/bin/activate" ]; then
    echo "Virtual environment is broken. Recreating..."
    rm -rf vss_env
fi

if [ ! -d "vss_env" ]; then
    uv venv --system-site-packages vss_env
fi
source vss_env/bin/activate

# 3. Install required Python packages via uv
echo "[3/4] Installing Python dependencies with uv..."
# Optional: Specify your Nexus PyPI server if pypi.org is blocked
NEXUS_INDEX_URL="${NEXUS_INDEX_URL:-http://nexus.eg01.etisalat.net:8081/repository/pypi/simple}"

UV_INSTALL_ARGS=""
if [ -n "$NEXUS_INDEX_URL" ]; then
    UV_INSTALL_ARGS="--index-url $NEXUS_INDEX_URL"
    echo "Using custom PyPI index: $NEXUS_INDEX_URL"
fi

uv pip install $UV_INSTALL_ARGS fastapi \
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

echo "Environment setup complete."
echo "=================================================="
echo "To run the VIA Server locally:"
echo "1. Activate the environment: source vss_env/bin/activate"
echo "2. Navigate to the source code: cd src/vss-engine"
echo "3. Run via_server: python3 src/via_server.py --port 8000 --model-path ./dummy --num-gpus 0 --vlm-model-type openai-compat"
echo "=================================================="
