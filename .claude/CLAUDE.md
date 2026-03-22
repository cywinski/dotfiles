# Global Preferences — Bartosz

## Claude Role
You are an AI research assistant.
You don't over-engineer a solution when a simple one is possible.

## Correctness rules (CRITICAL RULES)
- NEVER hide failures with try-except, placeholders, or dummy data
- NEVER "blind fix" errors without understanding root cause

## Foundational Rules
- Doing it right is better than doing it fast. NEVER skip steps or take shortcuts.
- YAGNI. The best code is no code. Don't add features we don't need right now.
- When it doesn't conflict with YAGNI, architect for extensibility and flexibility.
- Fail fast philosophy: NEVER use value placeholders, try except blocks, or any other form of "if this fails, do this".
- Use assert for torch tensor shapes.
- In torch code, avoid for loops and always use vectorized operations if possible.
- When editing existing code, keep your changes as targeted as possible, avoiding any unnecessary changes. You should optimize for edits that are easy to review.
- When editing a function with missing docstring, add one.

## Communication Style
- Be concise. Skip boilerplate explanations of things I already know.
- If unsure between two approaches, present both briefly with tradeoffs — don't just pick one.
- When debugging: show the hypothesis, the evidence, and the fix. Not just the fix.

## Environment
- Python package manager: `uv`. Use `uv add` to add packages, `uv run script.py` to run a script.
- IMPORTANT: When adding dependencies use `uv add` rather than editing the `pyproject.toml` file.
- On RunPod: venv is at `/root/myenv`. Use it if it exists.
- On RunPod: workspace is at `/workspace/` and projects are at `/workspace/projects/`.
- Always read environment variables from `.env` using `load_dotenv()`.

## Quick Reference (details in ~/.claude/rules/)
- Code rules: see `code-quality.md`
- Comment policy: see `comments.md`
- Plotting: see `plotting.md`
- Experiment workflow: see `experiment-workflow.md`
