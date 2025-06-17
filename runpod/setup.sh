#!/bin/bash

# Minimal RunPod Setup Script
# Only sets up non-persistent, pod-wide configurations
# /workspace is preserved, so we avoid installing things there

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values (can be overridden by environment variables)
GITHUB_USERNAME="${GITHUB_USERNAME:-cywinski}"
GITHUB_EMAIL="${GITHUB_EMAIL:-bcywinski11@gmail.com}"
SSH_KEY_TYPE="${SSH_KEY_TYPE:-ed25519}"

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}🚀 RunPod Minimal Setup${NC}"
echo "Setting up non-persistent pod-wide configurations..."
echo ""
echo "GitHub Username: $GITHUB_USERNAME"
echo "GitHub Email: $GITHUB_EMAIL"
echo "SSH Key Type: $SSH_KEY_TYPE"
echo ""

# Stage 1: Install system dependencies
log_info "Stage 1: Installing system dependencies..."
"$SCRIPT_DIR/install_system.sh"

# Stage 2: Set up environment variables
log_info "Stage 2: Setting up environment variables..."
"$SCRIPT_DIR/setup_env.sh"

# Stage 3: Set up SSH and GitHub
log_info "Stage 3: Setting up SSH keys and GitHub..."
"$SCRIPT_DIR/setup_github.sh" "$GITHUB_USERNAME" "$GITHUB_EMAIL" "$SSH_KEY_TYPE"

log_success "RunPod minimal setup completed!"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Add your SSH public key to GitHub (displayed above)"
echo "2. Test SSH: ssh -T git@github.com"
echo "3. Your /workspace directory is preserved between pod restarts"
echo "4. Clone your repositories to /workspace for persistence"
echo ""
echo -e "${GREEN}Environment is ready!${NC}"
