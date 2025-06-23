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

# --- NEW: Install Oh My Tmux ---------------------------------------------------
OH_MY_TMUX_DIR="/workspace/config/.tmux"
if [[ ! -d "$OH_MY_TMUX_DIR" ]]; then
    log_info "Cloning Oh My Tmux configuration..."
    git clone --depth 1 https://github.com/gpakosz/.tmux.git "$OH_MY_TMUX_DIR"
else
    log_info "Updating Oh My Tmux configuration..."
    git -C "$OH_MY_TMUX_DIR" pull --ff-only || true
fi

# Provide a custom tmux.conf.local (persistent)
if [[ ! -f /workspace/config/.tmux.conf.local && -f "$SCRIPT_DIR/tmux.conf.local" ]]; then
    log_info "Copying custom tmux.conf.local to workspace..."
    cp "$SCRIPT_DIR/tmux.conf.local" /workspace/config/.tmux.conf.local
fi

# Don't set fish as default shell system-wide to avoid SSH hook conflicts
# Instead, make it easy to switch to fish when desired
log_info "Fish installed and configured (use 'fish' to start)"

# Add fish starter aliases to bashrc for easy access
if ! grep -q "alias f=" /root/.bashrc; then
    echo "alias f='fish'" >> /root/.bashrc
    echo "alias fishell='fish'" >> /root/.bashrc
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

# Node.js aliases
alias n='node'
alias ni='npm install'
alias nid='npm install --save-dev'
alias nr='npm run'
alias ns='npm start'
alias nt='npm test'
alias nb='npm run build'

# GPU aliases
alias smi='nvidia-smi'
EOF
fi

# Create projects directory
mkdir -p /workspace/projects

# Create symlinks to persistent configs
# Link Oh My Tmux main configuration
if [[ -f "$OH_MY_TMUX_DIR/.tmux.conf" ]]; then
    log_info "Linking Oh My Tmux configuration..."
    ln -sf "$OH_MY_TMUX_DIR/.tmux.conf" /root/.tmux.conf
fi

# Link custom local configuration if present
if [[ -f /workspace/config/.tmux.conf.local ]]; then
    log_info "Linking custom tmux.conf.local..."
    ln -sf /workspace/config/.tmux.conf.local /root/.tmux.conf.local
fi

if [[ -f /workspace/config/fish/config.fish ]]; then
    log_info "Linking fish configuration..."
    mkdir -p /root/.config/fish
    ln -sf /workspace/config/fish/config.fish /root/.config/fish/config.fish

    # Reload fish configuration if fish is running
    if command -v fish >/dev/null 2>&1; then
        log_info "Reloading fish configuration..."
        fish -c "source /root/.config/fish/config.fish" 2>/dev/null || true
    fi
fi

# Source workspace aliases if they exist
if [[ -f /workspace/config/workspace_aliases.sh ]]; then
    if ! grep -q "workspace_aliases.sh" /root/.bashrc; then
        log_info "Adding workspace aliases to bashrc..."
        echo "source /workspace/config/workspace_aliases.sh" >> /root/.bashrc
    fi
    # Source aliases immediately for current session
    log_info "Sourcing workspace aliases for current session..."
    source /workspace/config/workspace_aliases.sh
fi

# Add welcome script if it exists
if [[ -f /workspace/config/welcome.sh ]]; then
    if ! grep -q "welcome.sh" /root/.bashrc; then
        log_info "Adding welcome script to bashrc..."
        echo "/workspace/config/welcome.sh" >> /root/.bashrc
    fi
fi

# Source environment variables for current session
log_info "Sourcing environment variables for current session..."
source /root/.bashrc

# Source tmux configuration if tmux is running
if command -v tmux >/dev/null 2>&1 && tmux list-sessions >/dev/null 2>&1; then
    log_info "Reloading tmux configuration..."
    tmux source-file /root/.tmux.conf 2>/dev/null || true
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
if [[ -f /workspace/.ssh/id_ed25519.pub ]]; then
    echo -e "${BLUE}Your SSH public key:${NC}"
    cat /root/.ssh/id_ed25519.pub
    echo ""
fi

echo -e "${BLUE}Your /workspace directory is preserved between pod restarts${NC}"
echo -e "${GREEN}Environment is ready!${NC}"
echo ""
echo -e "${YELLOW}To use fish shell:${NC}"
echo "1. Start fish: fish (or use alias 'f')"
echo "2. Start tmux with fish: tmux (fish config will auto-load)"
echo "3. Fish aliases: projects, ws, gs, etc. (work in fish sessions)"
echo ""
echo -e "${YELLOW}Note:${NC} Bash remains default shell to avoid SSH conflicts"
echo "Fish is fully configured and ready - just type 'fish' to use it!"
