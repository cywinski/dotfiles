#!/bin/bash

# RunPod Bootstrap Installer
# Simple one-liner bootstrap for the minimal setup

set -e

# Default dotfiles repo (update this to your actual repo)
DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/cywinski/dotfiles.git}"
INSTALL_DIR="/tmp/dotfiles-setup"

echo "🚀 RunPod Minimal Setup Bootstrap"
echo "Downloading dotfiles from: $DOTFILES_REPO"

# Install git if not present
if ! command -v git >/dev/null 2>&1; then
    echo "Installing git..."
    apt-get update -y
    apt-get install -y git
fi

# Clone and run setup
if [[ -d "$INSTALL_DIR" ]]; then
    rm -rf "$INSTALL_DIR"
fi

git clone "$DOTFILES_REPO" "$INSTALL_DIR"
cd "$INSTALL_DIR/runpod"
chmod +x *.sh
exec ./setup.sh
