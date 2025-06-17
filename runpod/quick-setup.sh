#!/bin/bash

# Quick RunPod Setup Script
# This is a wrapper script that provides common defaults for faster setup

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 RunPod Quick Setup${NC}"
echo "This script will set up your RunPod environment with common defaults."
echo ""

# Check if setup.sh exists
if [[ ! -f "$(dirname "$0")/setup.sh" ]]; then
    echo -e "${RED}Error: setup.sh not found in the same directory${NC}"
    exit 1
fi

# Get GitHub username
read -p "GitHub Username: " GITHUB_USERNAME
if [[ -z "$GITHUB_USERNAME" ]]; then
    echo -e "${RED}Error: GitHub username is required${NC}"
    exit 1
fi

# Get GitHub email
read -p "GitHub Email: " GITHUB_EMAIL
if [[ -z "$GITHUB_EMAIL" ]]; then
    echo -e "${RED}Error: GitHub email is required${NC}"
    exit 1
fi

# Get repository URL
read -p "Repository URL (https://github.com/user/repo.git): " REPO_URL
if [[ -z "$REPO_URL" ]]; then
    echo -e "${RED}Error: Repository URL is required${NC}"
    exit 1
fi

# Optional: Python version
read -p "Python version [3.11]: " PYTHON_VERSION
PYTHON_VERSION=${PYTHON_VERSION:-3.11}

echo ""
echo -e "${YELLOW}Starting setup with:${NC}"
echo "  GitHub Username: $GITHUB_USERNAME"
echo "  GitHub Email: $GITHUB_EMAIL"
echo "  Repository: $REPO_URL"
echo "  Python Version: $PYTHON_VERSION"
echo ""

# Run the main setup script
exec "$(dirname "$0")/setup.sh" \
    --github-username "$GITHUB_USERNAME" \
    --github-email "$GITHUB_EMAIL" \
    --repo-url "$REPO_URL" \
    --python-version "$PYTHON_VERSION" \
    --cursor-extensions "$(dirname "$0")/cursor_extensions.txt"
