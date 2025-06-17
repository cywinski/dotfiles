#!/bin/bash

# First-time RunPod Setup Script
# Installs essential development tools under /workspace for persistence
# Run this only once when setting up a new RunPod for the first time

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[WORKSPACE]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[WORKSPACE]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WORKSPACE]${NC} $1"
}

echo -e "${BLUE}🚀 RunPod First-Time Workspace Setup${NC}"
echo "Installing essential tools under /workspace for persistence..."
echo ""

# Ensure we're working in /workspace
cd /workspace

# Create essential directories
log_info "Creating essential directories..."
mkdir -p /workspace/config

# Install tmux and fish using apt
log_info "Installing tmux and fish using apt..."
apt update
apt install -y tmux fish

# Create fish config directory
mkdir -p /workspace/config/fish

log_success "tmux and fish installed via apt"



# Copy configuration files if they exist
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Copy tmux config
if [[ -f "$SCRIPT_DIR/tmux.conf" ]]; then
    log_info "Copying tmux configuration..."
    cp "$SCRIPT_DIR/tmux.conf" /workspace/config/.tmux.conf
    # Create symlink in home directory pointing to workspace config
    ln -sf /workspace/config/.tmux.conf /root/.tmux.conf
fi

# Copy fish config
if [[ -f "$SCRIPT_DIR/fish_config.fish" ]]; then
    log_info "Copying fish configuration..."
    mkdir -p /workspace/config/fish
    cp "$SCRIPT_DIR/fish_config.fish" /workspace/config/fish/config.fish
    # Create symlink in home directory pointing to workspace config
    mkdir -p /root/.config/fish
    ln -sf /workspace/config/fish/config.fish /root/.config/fish/config.fish
fi

# Set fish as default shell
log_info "Setting fish as default shell..."
chsh -s /usr/bin/fish root

# Create useful aliases and functions
log_info "Creating workspace-aware aliases..."
cat >> /workspace/config/workspace_aliases.sh << 'EOF'
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

# Source workspace aliases in bashrc
if ! grep -q "workspace_aliases.sh" /root/.bashrc; then
    echo "source /workspace/config/workspace_aliases.sh" >> /root/.bashrc
fi

# Create projects directory
mkdir -p /workspace/projects

# Create a welcome script
cat > /workspace/config/welcome.sh << 'EOF'
#!/bin/bash
echo "🚀 Welcome to your persistent RunPod workspace!"
echo "📁 Essential tools installed via apt:"
echo "   • tmux, fish (default shell)"
echo "📂 Your projects should go in /workspace/projects"
echo "⚙️  Configuration files in /workspace/config"
echo ""
echo "💡 Quick commands:"
echo "   ws         - cd to /workspace"
echo "   projects   - cd to /workspace/projects"
echo "   tm         - start tmux"
echo ""
EOF

chmod +x /workspace/config/welcome.sh

# Add welcome to bashrc
if ! grep -q "welcome.sh" /root/.bashrc; then
    echo "/workspace/config/welcome.sh" >> /root/.bashrc
fi

echo ""
log_success "First-time workspace setup completed!"
echo ""
echo -e "${YELLOW}✨ Your persistent workspace is ready!${NC}"
echo -e "${BLUE}Essential tools installed via apt:${NC}"
echo "  • tmux (/usr/bin/tmux)"
echo "  • fish (/usr/bin/fish) - set as default shell"
echo ""
echo -e "${GREEN}💡 Start a new shell session:${NC}"
echo "exec fish"
echo ""
echo -e "${BLUE}📁 Directory structure:${NC}"
echo "/workspace/"
echo "├── config/       # Configuration files"
echo "└── projects/     # Your development projects"
