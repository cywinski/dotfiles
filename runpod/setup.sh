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

# Stage 4: Install essential development tools
log_info "Stage 4: Installing essential development tools..."
apt update
apt install -y tmux fish

# Set fish as default shell if not already set
if [[ "$(getent passwd root | cut -d: -f7)" != "/usr/bin/fish" ]]; then
    log_info "Setting fish as default shell..."
    chsh -s /usr/bin/fish root
fi

# Set up configuration files and create symlinks
mkdir -p /workspace/config/fish

# Copy configuration files if they don't exist yet
if [[ ! -f /workspace/config/.tmux.conf && -f "$SCRIPT_DIR/tmux.conf" ]]; then
    log_info "Copying tmux configuration to workspace..."
    cp "$SCRIPT_DIR/tmux.conf" /workspace/config/.tmux.conf
fi

if [[ ! -f /workspace/config/fish/config.fish && -f "$SCRIPT_DIR/fish_config.fish" ]]; then
    log_info "Copying fish configuration to workspace..."
    cp "$SCRIPT_DIR/fish_config.fish" /workspace/config/fish/config.fish
fi

# Create workspace aliases file if it doesn't exist
if [[ ! -f /workspace/config/workspace_aliases.sh ]]; then
    log_info "Creating workspace aliases..."
    cat > /workspace/config/workspace_aliases.sh << 'EOF'
# Workspace-aware aliases
alias tm='tmux'

# Quick navigation
alias ws='cd /workspace'
alias projects='cd /workspace/projects'

# Git aliases for workspace
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline'

# Development aliases
alias py='python'
alias pip='uv pip'
EOF
fi

# Create projects directory
mkdir -p /workspace/projects

# Create symlinks to persistent configs
if [[ -f /workspace/config/.tmux.conf ]]; then
    log_info "Linking tmux configuration..."
    ln -sf /workspace/config/.tmux.conf /root/.tmux.conf
fi

if [[ -f /workspace/config/fish/config.fish ]]; then
    log_info "Linking fish configuration..."
    mkdir -p /root/.config/fish
    ln -sf /workspace/config/fish/config.fish /root/.config/fish/config.fish
fi

# Source workspace aliases if they exist
if [[ -f /workspace/config/workspace_aliases.sh ]]; then
    if ! grep -q "workspace_aliases.sh" /root/.bashrc; then
        log_info "Adding workspace aliases to bashrc..."
        echo "source /workspace/config/workspace_aliases.sh" >> /root/.bashrc
    fi
fi

# Add welcome script if it exists
if [[ -f /workspace/config/welcome.sh ]]; then
    if ! grep -q "welcome.sh" /root/.bashrc; then
        log_info "Adding welcome script to bashrc..."
        echo "/workspace/config/welcome.sh" >> /root/.bashrc
    fi
fi

log_success "RunPod minimal setup completed!"
echo ""
if [[ -f /workspace/.ssh/id_ed25519.pub ]]; then
    echo -e "${GREEN}SSH key ready! (persistent across restarts)${NC}"
    echo "Test connection: ssh -T git@github.com"
else
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Add your SSH public key to GitHub (displayed above)"
    echo "2. Test SSH: ssh -T git@github.com"
fi
echo ""
echo -e "${BLUE}Your /workspace directory is preserved between pod restarts${NC}"
echo -e "${GREEN}Environment is ready!${NC}"
