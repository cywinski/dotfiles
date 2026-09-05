#!/bin/bash
# ABOUTME: Links shared research instructions and skills into Codex discovery paths.
# ABOUTME: Preserves existing files and supports an isolated target directory for verification.
set -euo pipefail

dotfiles_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
target_dir="${1:-$HOME}"

link_source() {
    # Link one source, retaining any existing destination as a backup.
    local src="$1" dst="$2" backup
    if [[ -L "$dst" && "$dst" -ef "$src" ]]; then
        echo "[OK] $dst"
        return
    fi
    if [[ -e "$dst" || -L "$dst" ]]; then
        backup="$(mktemp -d "${dst}.backup.XXXXXXXX")"
        mv "$dst" "$backup/original"
        echo "[BACKUP] $dst -> $backup/original"
    fi
    ln -s "$src" "$dst"
    echo "[LINK] $dst -> $src"
}

mkdir -p "$target_dir/.codex" "$target_dir/.agents/skills"
link_source "$dotfiles_dir/.claude/CLAUDE.md" "$target_dir/.codex/AGENTS.md"
for skill in "$dotfiles_dir"/.claude/skills/* "$dotfiles_dir"/.codex/skills/*; do
    [[ -f "$skill/SKILL.md" ]] || continue
    link_source "$skill" "$target_dir/.agents/skills/$(basename "$skill")"
done

echo "Codex shares the Claude instruction and skill sources. Start a fresh session."
