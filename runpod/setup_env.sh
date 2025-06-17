#!/bin/bash

# Setup Environment Variables
# Sets up system-wide environment variables that are not preserved between pod restarts

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[ENV]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[ENV]${NC} $1"
}

# Add uv to PATH
log_info "Adding uv to PATH..."
export PATH="$HOME/.local/bin:$PATH"
echo 'export PATH="$HOME/.local/bin:$PATH"' >> /root/.bashrc

# Set up HuggingFace environment variables
log_info "Setting up HuggingFace environment variables..."
echo "export HF_HOME=/workspace/hf" >> /root/.bashrc
echo "export HF_HUB_ENABLE_HF_TRANSFER=1" >> /root/.bashrc

# Set up VSCode/Cursor environment variables for persistence
log_info "Setting up VSCode/Cursor environment variables..."
echo "export VSCODE_EXTENSIONS=/workspace/.vscode-server/extensions" >> /root/.bashrc
echo "export VSCODE_USER_DATA_DIR=/workspace/.vscode-server/data" >> /root/.bashrc
echo "export CURSOR_USER_DATA_DIR=/workspace/.cursor-server/data" >> /root/.bashrc
echo "export CURSOR_EXTENSIONS_DIR=/workspace/.cursor-server/extensions" >> /root/.bashrc

# Set up additional cache directories for persistence
log_info "Setting up additional cache directories..."
echo "export npm_config_cache=/workspace/.npm" >> /root/.bashrc
echo "export PIP_CACHE_DIR=/workspace/.pip-cache" >> /root/.bashrc
echo "export UV_CACHE_DIR=/workspace/.uv-cache" >> /root/.bashrc

# Create workspace subdirectories
log_info "Creating workspace subdirectories..."
mkdir -p /workspace/hf
mkdir -p /workspace/.vscode-server/{extensions,data}
mkdir -p /workspace/.cursor-server/{extensions,data}
mkdir -p /workspace/.npm
mkdir -p /workspace/.pip-cache
mkdir -p /workspace/.uv-cache

log_success "Environment variables configured"
