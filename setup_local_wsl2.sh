#!/bin/bash
# Local Execution Setup Script for VSS Engine (No-Sudo/User-Level)
# This script installs Python dependencies using 'uv'.
# Note: System-level libraries (GStreamer, FFmpeg, etc.) must be pre-installed by an admin.

set -e

echo "=================================================="
echo "Setting up VSS Engine for local execution (User-Level)"
echo "=================================================="

# 1. System Dependencies Information
echo "[1/3] Checking/Listing required system dependencies..."
echo "Note: This script skips system package installation as 'sudo' is not used."
echo "Please ensure the following are installed on your system (ask an admin if needed):"
echo "  - GStreamer 1.0 (plugins: bad, good, ugly, libav)"
echo "  - FFmpeg"
echo "  - Python3 headers and GObject Introspection"
echo "  - Cairo development headers"
echo "--------------------------------------------------"

# 2. Install uv (modern Python package manager)
echo "[2/3] Installing uv..."
if ! command -v uv >/dev/null 2>&1; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
    # Ensure uv is in the path for the current script
    export PATH="$HOME/.cargo/bin:$PATH"
else
    echo "uv is already installed."
fi

# 3. Create and setup virtual environment with uv
echo "[3/3] Setting up Python virtual environment with uv..."
if [ ! -d "vss_env" ]; then
    uv venv --system-site-packages vss_env
fi
source vss_env/bin/activate

# 4. Install required Python packages via uv
echo "Installing Python dependencies with uv..."
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
