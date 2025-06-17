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
echo "Setting up persistent configuration files and directories..."
echo ""

# Ensure we're working in /workspace
cd /workspace

# Create essential directories
log_info "Creating essential directories..."
mkdir -p /workspace/config

# Create fish config directory
mkdir -p /workspace/config/fish



# Copy configuration files if they exist
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Copy tmux config
if [[ -f "$SCRIPT_DIR/tmux.conf" ]]; then
    log_info "Copying tmux configuration..."
    cp "$SCRIPT_DIR/tmux.conf" /workspace/config/.tmux.conf
fi

# Copy fish config
if [[ -f "$SCRIPT_DIR/fish_config.fish" ]]; then
    log_info "Copying fish configuration..."
    mkdir -p /workspace/config/fish
    cp "$SCRIPT_DIR/fish_config.fish" /workspace/config/fish/config.fish
fi



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

# Create projects directory
mkdir -p /workspace/projects

# Create a welcome script
cat > /workspace/config/welcome.sh << 'EOF'
#!/bin/bash
echo "🚀 Welcome to your persistent RunPod workspace!"
echo "📁 tmux and fish are installed fresh each pod restart"
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

echo ""
log_success "First-time workspace setup completed!"
echo ""
echo -e "${YELLOW}✨ Your persistent workspace is ready!${NC}"
echo -e "${BLUE}Configuration setup complete:${NC}"
echo "  • tmux config copied to /workspace/config"
echo "  • fish config copied to /workspace/config"
echo "  • workspace aliases and welcome script created"
echo ""
echo -e "${GREEN}💡 Run the main setup to install tmux/fish:${NC}"
echo "./setup.sh"
echo ""
echo -e "${GREEN}Then start fish shell:${NC}"
echo "fish"
echo ""
echo -e "${BLUE}📁 Directory structure:${NC}"
echo "/workspace/"
echo "├── config/       # Configuration files"
echo "└── projects/     # Your development projects"
