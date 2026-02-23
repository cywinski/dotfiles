#!/bin/bash

# Symlink Claude Code configs from this dotfiles repo into ~/.claude/
# Idempotent — safe to re-run. Works on macOS and Linux.

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_SRC="$DOTFILES_DIR/.claude"
CLAUDE_DST="$HOME/.claude"

# Items to symlink (files and directories)
MANAGED_ITEMS=(
    CLAUDE.md
    settings.json
    rules
    commands
    hooks
    skills
)

mkdir -p "$CLAUDE_DST"

for item in "${MANAGED_ITEMS[@]}"; do
    src="$CLAUDE_SRC/$item"
    dst="$CLAUDE_DST/$item"

    # Skip if source doesn't exist in repo
    if [[ ! -e "$src" ]]; then
        echo "[SKIP] $item (not in dotfiles repo)"
        continue
    fi

    # Already a correct symlink — nothing to do
    if [[ -L "$dst" ]] && [[ "$(readlink "$dst")" == "$src" ]]; then
        echo "[OK]   $item"
        continue
    fi

    # Back up existing non-symlink target
    if [[ -e "$dst" || -L "$dst" ]]; then
        backup="$dst.backup.$(date +%Y%m%d%H%M%S)"
        echo "[BACKUP] $dst -> $backup"
        mv "$dst" "$backup"
    fi

    ln -s "$src" "$dst"
    echo "[LINK] $dst -> $src"
done

echo ""
echo "Claude Code config symlinks are set up."
