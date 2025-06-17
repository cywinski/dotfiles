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
mkdir -p /workspace/bin
mkdir -p /workspace/tools
mkdir -p /workspace/config

# Add workspace bin to PATH if not already there
if ! grep -q "/workspace/bin" /root/.bashrc; then
    log_info "Adding /workspace/bin to PATH..."
    echo 'export PATH="/workspace/bin:$PATH"' >> /root/.bashrc
fi

# Install tmux from source for persistence
if [[ ! -f /workspace/bin/tmux ]]; then
    log_info "Installing tmux to /workspace..."
    cd /workspace/tools

    # Download and compile tmux
    wget https://github.com/tmux/tmux/releases/download/3.4/tmux-3.4.tar.gz
    tar -xzf tmux-3.4.tar.gz
    cd tmux-3.4

    # Install dependencies for building tmux
    apt-get update -y
    apt-get install -y libevent-dev ncurses-dev build-essential bison pkg-config

    # Configure and install to /workspace
    ./configure --prefix=/workspace
    make && make install

    # Cleanup
    cd /workspace/tools
    rm -rf tmux-3.4*

    log_success "tmux installed to /workspace/bin/tmux"
else
    log_info "tmux already installed in /workspace"
fi

# Install fish shell to /workspace
if [[ ! -f /workspace/bin/fish ]]; then
    log_info "Installing fish shell to /workspace..."
    cd /workspace/tools

    # Download fish
    wget https://download.opensuse.org/repositories/shells:/fish:/release:/3/Debian_12/amd64/fish_3.7.1-1_amd64.deb
    dpkg -i fish_3.7.1-1_amd64.deb || apt-get install -f -y

    # Copy fish to workspace
    cp /usr/bin/fish /workspace/bin/fish

    # Create fish config directory
    mkdir -p /workspace/config/fish

    log_success "fish installed to /workspace/bin/fish"
else
    log_info "fish already installed in /workspace"
fi



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
chsh -s /workspace/bin/fish root

# Create useful aliases and functions
log_info "Creating workspace-aware aliases..."
cat >> /workspace/config/workspace_aliases.sh << 'EOF'
# Workspace-aware aliases
alias tm='/workspace/bin/tmux'

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
echo "📁 Essential tools installed in /workspace/bin:"
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
echo -e "${BLUE}Essential tools installed:${NC}"
echo "  • tmux (/workspace/bin/tmux)"
echo "  • fish (/workspace/bin/fish) - set as default shell"
echo ""
echo -e "${GREEN}💡 Start a new shell session:${NC}"
echo "exec fish"
echo ""
echo -e "${BLUE}📁 Directory structure:${NC}"
echo "/workspace/"
echo "├── bin/          # Your persistent tools"
echo "├── config/       # Configuration files"
echo "├── projects/     # Your development projects"
echo "└── tools/        # Build artifacts"
