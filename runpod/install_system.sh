#!/bin/bash

# Install System Dependencies
# Only installs system-level packages that are not preserved between pod restarts

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[SYSTEM]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SYSTEM]${NC} $1"
}

# Update system packages
log_info "Updating system packages..."
apt-get update -y

# Install essential system packages
log_info "Installing essential system packages..."
apt-get install -y \
    curl \
    wget \
    git \
    build-essential \
    python3-dev \
    python3-pip \
    openssh-client \
    unzip \
    software-properties-common \
    vim

# Install Node.js via nvm (Node Version Manager)
log_info "Installing Node.js via nvm..."
if ! command -v node >/dev/null 2>&1; then
    # Download and install nvm
    log_info "Installing nvm..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

    # Source nvm in current session
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

        # Download and install Node.js LTS (v22)
    log_info "Installing Node.js v22 via nvm..."
    nvm install 22
    nvm use 22

    # Install global npm packages
    log_info "Installing global npm packages..."
    npm install -g @anthropic-ai/claude-code

    # Verify installation
    NODE_VERSION=$(node -v)
    NPM_VERSION=$(npm -v)
    NVM_CURRENT=$(nvm current)

    log_success "Node.js $NODE_VERSION and npm $NPM_VERSION installed successfully"
    log_success "@anthropic-ai/claude-code installed globally"
    log_info "nvm current version: $NVM_CURRENT"
else
    log_info "Node.js already installed: $(node --version)"
fi

# Install uv (Python package manager)
log_info "Installing uv..."
if ! command -v uv >/dev/null 2>&1; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
    log_success "uv installed successfully"
else
    log_info "uv already installed"
fi

log_success "System dependencies installed"
