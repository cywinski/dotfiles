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

# Set up SSH directories
log_info "Setting up SSH directory..."
mkdir -p /workspace/.ssh
chmod 700 /workspace/.ssh
chown root:root /workspace/.ssh

mkdir -p /root/.ssh
chmod 700 /root/.ssh
chown root:root /root/.ssh

# Generate SSH key if it doesn't exist in persistent storage
SSH_KEY_PATH="/workspace/.ssh/id_$SSH_KEY_TYPE"
if [[ ! -f "$SSH_KEY_PATH" ]]; then
    log_info "Generating SSH key ($SSH_KEY_TYPE)..."
    ssh-keygen -t "$SSH_KEY_TYPE" -f "$SSH_KEY_PATH" -N "" -C "$GITHUB_EMAIL"
    # Set proper permissions for SSH keys
    chmod 600 "$SSH_KEY_PATH"
    chmod 644 "${SSH_KEY_PATH}.pub"
    chown root:root "$SSH_KEY_PATH" "${SSH_KEY_PATH}.pub"
    log_success "SSH key generated in persistent storage"
else
    log_info "SSH key already exists in persistent storage"
fi

# Ensure SSH key permissions are correct (in case they were corrupted)
if [[ -f "$SSH_KEY_PATH" ]]; then
    chmod 600 "$SSH_KEY_PATH"
    chown root:root "$SSH_KEY_PATH"
fi
if [[ -f "${SSH_KEY_PATH}.pub" ]]; then
    chmod 644 "${SSH_KEY_PATH}.pub"
    chown root:root "${SSH_KEY_PATH}.pub"
fi

# Set up Git configuration
log_info "Configuring Git..."
git config --global user.name "$GITHUB_USERNAME"
git config --global user.email "$GITHUB_EMAIL"
git config --global init.defaultBranch main

# Copy SSH config to both locations
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/ssh_config" ]]; then
    # Copy to persistent storage if not exists
    if [[ ! -f /workspace/.ssh/config ]]; then
        log_info "Copying SSH configuration to persistent storage..."
        cp "$SCRIPT_DIR/ssh_config" /workspace/.ssh/config
        chmod 600 /workspace/.ssh/config
        chown root:root /workspace/.ssh/config
    fi

    # Always copy to /root/.ssh for SSH to use
    log_info "Setting up SSH configuration..."
    cp /workspace/.ssh/config /root/.ssh/config
    chmod 600 /root/.ssh/config
    chown root:root /root/.ssh/config
fi

# Create symlinks for SSH keys (these are the large files we want to persist)
if [[ -f "/workspace/.ssh/id_$SSH_KEY_TYPE" ]]; then
    log_info "Linking SSH keys..."
    ln -sf "/workspace/.ssh/id_$SSH_KEY_TYPE" "/root/.ssh/id_$SSH_KEY_TYPE"
    ln -sf "/workspace/.ssh/id_$SSH_KEY_TYPE.pub" "/root/.ssh/id_$SSH_KEY_TYPE.pub"
fi

# Display SSH public key
echo ""
log_success "SSH public key (add this to GitHub):"
echo ""
cat "${SSH_KEY_PATH}.pub"
echo ""

log_success "GitHub and SSH setup complete"
