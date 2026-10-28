#!/bin/bash
# ABOUTME: Installs Claude Code configuration links from this dotfiles checkout.
# ABOUTME: Also installs Codex links to the shared instructions and skills.

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

bash "$DOTFILES_DIR/setup-codex.sh"

# viz: the figure library the plotting skill makes every chart with. Cloned
# beside this checkout unless VIZ_DIR says otherwise, and installed editable
# from the clone, so `viz path` finds its templates and `git pull` updates it.
VIZ_DIR="${VIZ_DIR:-$(dirname "$DOTFILES_DIR")/viz}"
if [[ -d "$VIZ_DIR/.git" ]]; then
    git -C "$VIZ_DIR" pull --ff-only
else
    git clone https://github.com/safety-research/viz.git "$VIZ_DIR"
fi
uv tool install --quiet --force --editable "$VIZ_DIR"
"$(uv tool dir --bin)/viz" setup  # headless Chromium, which renders PNG and PDF
echo "[VIZ]  $(uv tool dir --bin)/viz -> $VIZ_DIR"

# An older viz install linked its own skill here; the plotting skill replaces it.
viz_skill="$CLAUDE_DST/skills/viz"
if [[ -L "$viz_skill" && "$(readlink "$viz_skill")" == "$VIZ_DIR"/* ]]; then
    rm "$viz_skill"
    echo "[UNLINK] $viz_skill (the plotting skill covers viz)"
fi
