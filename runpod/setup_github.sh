#!/bin/bash

# Setup GitHub and SSH
# Configures SSH keys and Git settings that are not preserved between pod restarts

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[GIT]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[GIT]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[GIT]${NC} $1"
}

# Check if arguments are provided
if [[ $# -lt 3 ]]; then
    echo "Usage: $0 <github_username> <github_email> <ssh_key_type>"
    exit 1
fi

GITHUB_USERNAME="$1"
GITHUB_EMAIL="$2"
SSH_KEY_TYPE="$3"

# Set up SSH directory
log_info "Setting up SSH directory..."
mkdir -p /root/.ssh
chmod 700 /root/.ssh

# Generate SSH key if it doesn't exist
SSH_KEY_PATH="/root/.ssh/id_$SSH_KEY_TYPE"
if [[ ! -f "$SSH_KEY_PATH" ]]; then
    log_info "Generating SSH key ($SSH_KEY_TYPE)..."
    ssh-keygen -t "$SSH_KEY_TYPE" -f "$SSH_KEY_PATH" -N "" -C "$GITHUB_EMAIL"
    log_success "SSH key generated"
else
    log_info "SSH key already exists"
fi

# Set up Git configuration
log_info "Configuring Git..."
git config --global user.name "$GITHUB_USERNAME"
git config --global user.email "$GITHUB_EMAIL"
git config --global init.defaultBranch main

# Copy SSH config if it exists
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/ssh_config" ]]; then
    log_info "Copying SSH configuration..."
    cp "$SCRIPT_DIR/ssh_config" /root/.ssh/config
    chmod 600 /root/.ssh/config
fi

# Display SSH public key
echo ""
log_success "SSH public key (add this to GitHub):"
echo ""
cat "${SSH_KEY_PATH}.pub"
echo ""

log_success "GitHub and SSH setup complete"
