#!/bin/bash

# RunPod Setup Script
# This script sets up a new RunPod environment to mirror your local development setup

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
GITHUB_USERNAME="cywinski"
GITHUB_EMAIL="bcywinski11@gmail.com"
SSH_KEY_TYPE="ed25519"
REPOSITORY_URL=""
PYTHON_VERSION="3.11"
WORKSPACE_DIR="/workspace"
CURSOR_EXTENSIONS_FILE="cursor_extensions.txt"

# Help function
show_help() {
    cat << EOF
RunPod Setup Script

This script sets up a new RunPod environment with all your development tools and configurations.

Usage: $0 [OPTIONS]

Required Options:
  -u, --github-username   GitHub username
  -e, --github-email      GitHub email
  -r, --repo-url          Repository URL to clone and set up

Optional Options:
  -k, --ssh-key-type      SSH key type (default: ed25519)
  -p, --python-version    Python version for uv (default: 3.11)
  -w, --workspace-dir     Workspace directory (default: /workspace)
  -c, --cursor-extensions Path to cursor extensions file
  -h, --help              Show this help message

Examples:
  $0 -u johndoe -e john@example.com -r https://github.com/johndoe/myproject.git
  $0 --github-username johndoe --github-email john@example.com --repo-url git@github.com:johndoe/myproject.git --python-version 3.12

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -u|--github-username)
            GITHUB_USERNAME="$2"
            shift 2
            ;;
        -e|--github-email)
            GITHUB_EMAIL="$2"
            shift 2
            ;;
        -r|--repo-url)
            REPOSITORY_URL="$2"
            shift 2
            ;;
        -k|--ssh-key-type)
            SSH_KEY_TYPE="$2"
            shift 2
            ;;
        -p|--python-version)
            PYTHON_VERSION="$2"
            shift 2
            ;;
        -w|--workspace-dir)
            WORKSPACE_DIR="$2"
            shift 2
            ;;
        -c|--cursor-extensions)
            CURSOR_EXTENSIONS_FILE="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# Validate required arguments
if [[ -z "$GITHUB_USERNAME" || -z "$GITHUB_EMAIL" || -z "$REPOSITORY_URL" ]]; then
    echo -e "${RED}Error: Missing required arguments${NC}"
    show_help
    exit 1
fi

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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

log_info "Starting RunPod setup with the following configuration:"
echo "  GitHub Username: $GITHUB_USERNAME"
echo "  GitHub Email: $GITHUB_EMAIL"
echo "  Repository URL: $REPOSITORY_URL"
echo "  SSH Key Type: $SSH_KEY_TYPE"
echo "  Python Version: $PYTHON_VERSION"
echo "  Workspace Directory: $WORKSPACE_DIR"
echo ""

# Update system packages
log_info "Updating system packages..."
apt-get update -y && apt-get upgrade -y

# Install essential packages
log_info "Installing essential packages..."
apt-get install -y \
    curl \
    wget \
    git \
    tmux \
    fish \
    tree \
    htop \
    vim \
    openssh-client \
    openssh-server \
    software-properties-common \
    build-essential \
    libssl-dev \
    libffi-dev \
    python3-dev \
    python3-pip \
    unzip

# Create workspace directory
log_info "Creating workspace directory: $WORKSPACE_DIR"
mkdir -p "$WORKSPACE_DIR"
cd "$WORKSPACE_DIR"

# Install uv (Python package manager)
log_info "Installing uv..."
curl -LsSf https://astral.sh/uv/install.sh | sh
export PATH="$HOME/.local/bin:$PATH"
echo 'export PATH="$HOME/.local/bin:$PATH"' >> /root/.bashrc

# Set up HuggingFace environment variables
log_info "Setting up HuggingFace environment variables..."
echo "export HF_HOME=/workspace/hf" >> /root/.bashrc
echo "export HF_HUB_ENABLE_HF_TRANSFER=1" >> /root/.bashrc

# Set up SSH
log_info "Setting up SSH..."
mkdir -p /root/.ssh
chmod 700 /root/.ssh

# Generate SSH key
log_info "Generating SSH key ($SSH_KEY_TYPE)..."
ssh-keygen -t "$SSH_KEY_TYPE" -f /root/.ssh/id_"$SSH_KEY_TYPE" -N "" -C "$GITHUB_EMAIL"

# Set up Git configuration
log_info "Configuring Git..."
git config --global user.name "$GITHUB_USERNAME"
git config --global user.email "$GITHUB_EMAIL"
git config --global init.defaultBranch main

# Copy SSH config if it exists
if [[ -f "$(dirname "$0")/ssh_config" ]]; then
    log_info "Copying SSH configuration..."
    cp "$(dirname "$0")/ssh_config" /root/.ssh/config
    chmod 600 /root/.ssh/config
fi

# Set up Fish shell as default
log_info "Setting up Fish shell..."
chsh -s /usr/bin/fish root

# Copy Fish configuration if it exists
if [[ -f "$(dirname "$0")/fish_config.fish" ]]; then
    log_info "Setting up Fish configuration..."
    mkdir -p /root/.config/fish
    cp "$(dirname "$0")/fish_config.fish" /root/.config/fish/config.fish
fi

# Set up tmux configuration
if [[ -f "$(dirname "$0")/tmux.conf" ]]; then
    log_info "Setting up tmux configuration..."
    cp "$(dirname "$0")/tmux.conf" /root/.tmux.conf
fi

# Install Cursor IDE
log_info "Installing Cursor IDE..."
curl -fsSL https://download.todesktop.com/210313leapyear-cursor/linux/appImage/x64 -o cursor.AppImage
chmod +x cursor.AppImage
mv cursor.AppImage /usr/local/bin/cursor

# Install Cursor extensions if extensions file is provided
if [[ -n "$CURSOR_EXTENSIONS_FILE" && -f "$CURSOR_EXTENSIONS_FILE" ]]; then
    log_info "Installing Cursor extensions..."
    while IFS= read -r extension; do
        if [[ -n "$extension" && ! "$extension" =~ ^# ]]; then
            log_info "Installing extension: $extension"
            cursor --install-extension "$extension" 2>/dev/null || log_warning "Failed to install extension: $extension"
        fi
    done < "$CURSOR_EXTENSIONS_FILE"
fi

# Copy Cursor settings if they exist
if [[ -f "$(dirname "$0")/cursor_settings.json" ]]; then
    log_info "Setting up Cursor configuration..."
    mkdir -p /root/.cursor-server/data/User
    cp "$(dirname "$0")/cursor_settings.json" /root/.cursor-server/data/User/settings.json
fi

# Clone and set up repository
log_info "Cloning repository: $REPOSITORY_URL"
REPO_NAME=$(basename "$REPOSITORY_URL" .git)
git clone "$REPOSITORY_URL" "$WORKSPACE_DIR/$REPO_NAME"
cd "$WORKSPACE_DIR/$REPO_NAME"

# Create virtual environment with uv
log_info "Creating Python virtual environment with uv..."
uv python install "$PYTHON_VERSION"
uv venv --python "$PYTHON_VERSION"

# Activate virtual environment and install dependencies
log_info "Installing Python dependencies..."
source .venv/bin/activate

# Install dependencies from requirements files
if [[ -f "requirements.txt" ]]; then
    log_info "Installing from requirements.txt..."
    uv pip install -r requirements.txt
fi

if [[ -f "pyproject.toml" ]]; then
    log_info "Installing from pyproject.toml..."
    uv pip install -e .
fi

# Install Flash Attention
log_info "Installing Flash Attention..."
uv pip install flash-attn --no-build-isolation

# Install Jupyter
log_info "Installing Jupyter..."
uv pip install jupyter jupyterlab ipykernel

# Install the virtual environment as a Jupyter kernel
log_info "Setting up Jupyter kernel..."
python -m ipykernel install --user --name="$REPO_NAME" --display-name="$REPO_NAME ($PYTHON_VERSION)"

# Display SSH public key for GitHub setup
log_info "Setup complete!"
log_success "Your SSH public key (add this to GitHub):"
echo ""
cat /root/.ssh/id_"$SSH_KEY_TYPE".pub
echo ""

log_info "Next steps:"
echo "1. Add the SSH public key above to your GitHub account"
echo "2. Test SSH connection: ssh -T git@github.com"
echo "3. Start a new Fish shell session: fish"
echo "4. Start tmux: tmux"
echo "5. Launch Jupyter: jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root"

log_success "RunPod setup completed successfully!"
