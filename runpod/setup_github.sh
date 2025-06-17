#!/bin/bash

# Setup GitHub and SSH
# Configures SSH keys and Git settings that are not preserved between pod restarts

set -e

# Set secure umask to ensure files are created with correct permissions
umask 077

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

log_error() {
    echo -e "\033[0;31m[GIT]${NC} $1" >&2
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

# Generate SSH key if it doesn't exist in persistent storage
SSH_KEY_PATH="/root/.ssh/id_$SSH_KEY_TYPE"
if [[ ! -f "$SSH_KEY_PATH" ]]; then
    log_info "Generating SSH key ($SSH_KEY_TYPE)..."
    ssh-keygen -t "$SSH_KEY_TYPE" -f "$SSH_KEY_PATH" -N "" -C "$GITHUB_EMAIL"
    log_success "SSH key generated in persistent storage"
else
    log_info "SSH key already exists in persistent storage"
fi

# Set proper permissions for SSH keys and directory
log_info "Setting SSH permissions..."
chmod 700 /workspace/.ssh
chmod 600 "$SSH_KEY_PATH"
chmod 644 "${SSH_KEY_PATH}.pub"

# Set up Git configuration
log_info "Configuring Git..."
git config --global user.name "$GITHUB_USERNAME"
git config --global user.email "$GITHUB_EMAIL"
git config --global init.defaultBranch main

# Set up SSH config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/ssh_config" ]]; then
    # Copy SSH config to persistent storage if it doesn't exist
    if [[ ! -f /workspace/.ssh/config ]]; then
        log_info "Copying SSH configuration to persistent storage..."
        cp "$SCRIPT_DIR/ssh_config" /workspace/.ssh/config
        chmod 600 /workspace/.ssh/config
    fi
fi

# Create or update SSH config to use the persistent key
SSH_CONFIG="/workspace/.ssh/config"
if [[ ! -f "$SSH_CONFIG" ]] || ! grep -q "IdentityFile /root/.ssh/id_$SSH_KEY_TYPE" "$SSH_CONFIG"; then
    log_info "Configuring SSH to use persistent key..."
    cat >> "$SSH_CONFIG" << EOF

Host github.com
  HostName github.com
  User git
  IdentityFile /root/.ssh/id_$SSH_KEY_TYPE
  IdentitiesOnly yes
EOF
    chmod 600 "$SSH_CONFIG"
fi

# Link entire .ssh directory to /root (this is the key part!)
log_info "Linking SSH directory to /root..."
rm -rf /root/.ssh
ln -s /workspace/.ssh /root/.ssh

# Bunch of GPT output to fix key
mkdir -p /workspace/ssh_keys
chmod 700 /workspace/ssh_keys
mv /workspace/.ssh/* /workspace/ssh_keys/
chmod 600 /workspace/ssh_keys/id_ed25519
chmod 644 /workspace/ssh_keys/id_ed25519.pub
chmod 600 /workspace/ssh_keys/config
rm -rf /root/.ssh
mkdir -p /root/.ssh
cp -r /workspace/ssh_keys/* /root/.ssh/
chmod 700 /root/.ssh
chmod 600 /root/.ssh/id_ed25519
chmod 644 /root/.ssh/id_ed25519.pub
chmod 600 /root/.ssh/config


# Display SSH public key
echo ""
log_success "SSH public key (add this to GitHub):"
echo ""
cat "${SSH_KEY_PATH}.pub"
echo ""

# Test SSH connection
log_info "Testing SSH connection to GitHub..."
if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    log_success "SSH connection to GitHub working!"
else
    log_warning "SSH connection test failed - you may need to add the key to GitHub first"
    echo "Run: ssh -T git@github.com"
fi

log_success "GitHub and SSH setup complete"
