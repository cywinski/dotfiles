#!/bin/bash

# Install Claude Code on RunPod and symlink configs from dotfiles repo.

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }

DOTFILES_REPO="https://github.com/cywinski/dotfiles.git"
DOTFILES_DIR="/workspace/dotfiles"

# --- Claude Code ---
if ! command -v claude >/dev/null 2>&1; then
    log_info "Installing Claude Code..."
    curl -fsSL https://claude.ai/install.sh | bash
else
    log_info "Claude Code already installed: $(claude --version)"
fi

# --- Dotfiles repo ---
if [[ -d "$DOTFILES_DIR/.git" ]]; then
    log_info "Updating dotfiles repo..."
    git -C "$DOTFILES_DIR" pull --ff-only || log_warning "Could not fast-forward dotfiles repo"
else
    log_info "Cloning dotfiles repo..."
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
fi

# --- Symlink configs ---
log_info "Setting up Claude Code config symlinks..."
bash "$DOTFILES_DIR/setup.sh"

log_success "Claude Code setup complete!"
