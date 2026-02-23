#!/usr/bin/env bash
# Auto-format Python files with ruff after Claude edits/writes them.
# Used as a PostToolUse hook for Edit|Write.

FILE=$(jq -r '.tool_input.file_path // empty')

if [ -n "$FILE" ] && echo "$FILE" | grep -q '\.py$' && command -v ruff >/dev/null 2>&1; then
    ruff format "$FILE" 2>/dev/null
fi

exit 0
