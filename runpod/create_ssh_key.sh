#!/bin/bash

# Standalone SSH Key Creation Script
# Creates SSH key in /root/.ssh with proper permissions

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[SSH]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SSH]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[SSH]${NC} $1"
}

# Default values
SSH_KEY_TYPE="${SSH_KEY_TYPE:-ed25519}"
GITHUB_EMAIL="${GITHUB_EMAIL:-user@example.com}"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--type)
            SSH_KEY_TYPE="$2"
            shift 2
            ;;
        -e|--email)
            GITHUB_EMAIL="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  -t, --type TYPE     SSH key type (default: ed25519)"
            echo "  -e, --email EMAIL   Email for SSH key comment (default: user@example.com)"
            echo "  -h, --help          Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo -e "${BLUE}🔑 SSH Key Creation${NC}"
echo "Key type: $SSH_KEY_TYPE"
echo "Email: $GITHUB_EMAIL"
echo ""

# Create SSH directory
log_info "Creating SSH directory..."
mkdir -p /root/.ssh
chmod 700 /root/.ssh

# Generate SSH key
SSH_KEY_PATH="/root/.ssh/id_$SSH_KEY_TYPE"
if [[ -f "$SSH_KEY_PATH" ]]; then
    log_warning "SSH key already exists at $SSH_KEY_PATH"
    read -p "Overwrite existing key? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Keeping existing SSH key"
        exit 0
    fi
fi

log_info "Generating SSH key ($SSH_KEY_TYPE)..."
ssh-keygen -t "$SSH_KEY_TYPE" -f "$SSH_KEY_PATH" -N "" -C "$GITHUB_EMAIL"

# Set correct permissions
log_info "Setting SSH permissions..."
chmod 600 "$SSH_KEY_PATH"
chmod 644 "${SSH_KEY_PATH}.pub"

# Create empty authorized_keys if it doesn't exist
if [[ ! -f /root/.ssh/authorized_keys ]]; then
    log_info "Creating empty authorized_keys..."
    touch /root/.ssh/authorized_keys
    chmod 600 /root/.ssh/authorized_keys
fi

# Create basic SSH config if it doesn't exist
if [[ ! -f /root/.ssh/config ]]; then
    log_info "Creating SSH config..."
    cat > /root/.ssh/config << EOF
Host github.com
  HostName github.com
  User git
  IdentityFile /root/.ssh/id_$SSH_KEY_TYPE
  IdentitiesOnly yes
EOF
    chmod 600 /root/.ssh/config
fi

# Display results
log_success "SSH key created successfully!"
echo ""
echo -e "${BLUE}SSH public key (add this to GitHub):${NC}"
echo ""
cat "${SSH_KEY_PATH}.pub"
echo ""
echo -e "${BLUE}File permissions:${NC}"
ls -la /root/.ssh/
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Add the public key above to your GitHub account"
echo "2. Test SSH connection: ssh -T git@github.com"