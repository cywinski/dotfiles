#!/bin/bash

# RunPod Bootstrap Installer
# This script can be run directly from GitHub to bootstrap your RunPod setup
#
# Usage:
# curl -fsSL https://raw.githubusercontent.com/yourusername/dotfiles/main/runpod/install.sh | bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 RunPod Bootstrap Installer${NC}"
echo "This script will download your dotfiles and start the setup process."
echo ""

# Default values
DOTFILES_REPO="https://github.com/yourusername/dotfiles.git"
BRANCH="main"
INSTALL_DIR="/tmp/dotfiles-setup"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --repo)
            DOTFILES_REPO="$2"
            shift 2
            ;;
        --branch)
            BRANCH="$2"
            shift 2
            ;;
        --help)
            cat << EOF
RunPod Bootstrap Installer

Usage: $0 [OPTIONS]

Options:
  --repo    GitHub repository URL for dotfiles (default: https://github.com/yourusername/dotfiles.git)
  --branch  Branch to checkout (default: main)
  --help    Show this help message

Example:
  $0 --repo https://github.com/myuser/dotfiles.git --branch develop

EOF
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

# Install git if not present
if ! command -v git >/dev/null 2>&1; then
    echo -e "${YELLOW}Installing git...${NC}"
    apt-get update -y
    apt-get install -y git
fi

# Clone dotfiles repository
echo -e "${BLUE}Cloning dotfiles repository...${NC}"
if [[ -d "$INSTALL_DIR" ]]; then
    rm -rf "$INSTALL_DIR"
fi

git clone -b "$BRANCH" "$DOTFILES_REPO" "$INSTALL_DIR"

# Make scripts executable
chmod +x "$INSTALL_DIR/runpod/setup.sh"
chmod +x "$INSTALL_DIR/runpod/quick-setup.sh"

# Run the quick setup
echo -e "${GREEN}Repository cloned successfully!${NC}"
echo -e "${BLUE}Starting RunPod setup...${NC}"
echo ""

cd "$INSTALL_DIR/runpod"
exec ./quick-setup.sh
