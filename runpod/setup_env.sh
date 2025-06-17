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

# Set up Cursor extensions environment variable
log_info "Setting up Cursor environment variables..."
echo "export CURSOR_EXTENSIONS_DIR=/workspace/.cursor-extensions" >> /root/.bashrc

# Create workspace subdirectories
log_info "Creating workspace subdirectories..."
mkdir -p /workspace/hf
mkdir -p /workspace/.cursor-extensions

log_success "Environment variables configured"
