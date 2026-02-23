---
description: Commit all changes and push to GitHub
allowed-tools: Bash
---

Commit all staged and unstaged changes and push to GitHub. Follow these steps:

1. Run `git status` and `git diff` (staged + unstaged) to see what changed.
2. Run `git log --oneline -5` to see recent commit message style.
3. Stage all relevant changes (prefer specific files over `git add -A`).
4. Write a concise commit message that follows the repo's existing style. Focus on the "why", not the "what".
5. Commit the changes.
6. Push to the current branch's remote.

Do NOT commit files that contain secrets (`.env`, credentials, API keys). Warn me if any are detected.
