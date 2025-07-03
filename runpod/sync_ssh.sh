#!/bin/bash

# SSH Synchronization Script
# Syncs SSH files between persistent storage (/workspace/.ssh) and active location (/root/.ssh)
# This avoids symlink issues while maintaining persistence

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[SSH-SYNC]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SSH-SYNC]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[SSH-SYNC]${NC} $1"
}

# Function to set correct SSH permissions
set_ssh_permissions() {
    local ssh_dir="$1"
    if [[ -d "$ssh_dir" ]]; then
        chmod 700 "$ssh_dir"
        find "$ssh_dir" -name "id_*" -not -name "*.pub" -exec chmod 600 {} \; 2>/dev/null || true
        find "$ssh_dir" -name "*.pub" -exec chmod 644 {} \; 2>/dev/null || true
        [[ -f "$ssh_dir/authorized_keys" ]] && chmod 600 "$ssh_dir/authorized_keys"
        [[ -f "$ssh_dir/config" ]] && chmod 600 "$ssh_dir/config"
        [[ -f "$ssh_dir/known_hosts" ]] && chmod 600 "$ssh_dir/known_hosts"
    fi
}

# Function to sync from workspace to root (setup)
sync_to_root() {
    log_info "Syncing SSH files from persistent storage to /root/.ssh..."

    # Create /root/.ssh if it doesn't exist
    mkdir -p /root/.ssh

    # Copy all files from workspace to root
    if [[ -d /workspace/.ssh ]] && [[ "$(ls -A /workspace/.ssh 2>/dev/null)" ]]; then
        cp -r /workspace/.ssh/* /root/.ssh/ 2>/dev/null || true
        log_success "SSH files copied to /root/.ssh"
    else
        log_warning "No SSH files found in persistent storage"
    fi

    # Set correct permissions
    set_ssh_permissions "/root/.ssh"
    set_ssh_permissions "/workspace/.ssh"

    log_success "SSH permissions set correctly"
}

# Function to sync from root to workspace (backup)
sync_to_workspace() {
    log_info "Syncing SSH files from /root/.ssh to persistent storage..."

    # Create workspace SSH dir if it doesn't exist
    mkdir -p /workspace/.ssh

    # Copy all files from root to workspace
    if [[ -d /root/.ssh ]] && [[ "$(ls -A /root/.ssh 2>/dev/null)" ]]; then
        cp -r /root/.ssh/* /workspace/.ssh/ 2>/dev/null || true
        log_success "SSH files backed up to persistent storage"
    else
        log_warning "No SSH files found in /root/.ssh"
    fi

    # Set correct permissions
    set_ssh_permissions "/workspace/.ssh"
    set_ssh_permissions "/root/.ssh"

    log_success "SSH permissions set correctly"
}

# Main execution
case "${1:-to_root}" in
    "to_root")
        sync_to_root
        ;;
    "to_workspace")
        sync_to_workspace
        ;;
    "both")
        sync_to_root
        ;;
    *)
        echo "Usage: $0 [to_root|to_workspace|both]"
        echo "  to_root: Copy from /workspace/.ssh to /root/.ssh (default)"
        echo "  to_workspace: Copy from /root/.ssh to /workspace/.ssh"
        echo "  both: Same as to_root"
        exit 1
        ;;
esac
