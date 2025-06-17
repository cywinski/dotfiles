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
    software-properties-common

# Install uv (Python package manager)
log_info "Installing uv..."
if ! command -v uv >/dev/null 2>&1; then
    curl -LsSf https://astral.sh/uv/install.sh | sh
    log_success "uv installed successfully"
else
    log_info "uv already installed"
fi

log_success "System dependencies installed"
