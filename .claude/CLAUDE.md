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
Note: You can check if you are on RunPod by checking if the `RUNPOD_POD_ID` environment variable is set.

- Python package manager: `uv`. Use `uv add` to add packages, `uv run script.py` to run a script.
- IMPORTANT: When adding dependencies use `uv add` rather than editing the `pyproject.toml` file.
- On RunPod: venv is at `/root/myenv`. Use it if it exists.
- On RunPod: workspace is at `/workspace/` and projects are at `/workspace/projects/`.
- On RunPod: to install a package, use `uv pip install package_name`. To run a script, activate the venv and run `python script.py`.
- Always read environment variables from `.env` using `load_dotenv()`.

## Code Quality

- Make the SMALLEST reasonable changes to achieve the desired outcome.
- STRONGLY prefer simple, clean, maintainable solutions over clever or complex ones. Readability and maintainability are PRIMARY CONCERNS, even at the cost of conciseness or performance.
- WORK HARD to reduce code duplication, even if the refactoring takes extra effort.
- NEVER throw away or rewrite implementations without EXPLICIT permission. If considering this, STOP and ask first.
- Get approval before implementing ANY backward compatibility.
- Fix broken things immediately when you find them. Don't ask permission to fix bugs.

### Python Style
- Formatter: Ruff (line length: 88)
- Linter: Ruff check
- Type hints: Use for public APIs
- Docstrings: Google style
- Use Fire library instead of argparse
- All code files MUST start with a brief 2-line comment explaining what the file does. Each line MUST start with "ABOUTME: " to make them easily greppable.

### Code Comments

- Don't add obvious comments for code that is easy to understand.
- NEVER add comments explaining that something is "improved", "better", "new", "enhanced", or referencing what it used to be.
- NEVER add instructional comments telling developers what to do ("copy this pattern", "use this instead").
- Comments should explain WHAT the code does or WHY it exists, not how it's better than something else.
- If you're refactoring, remove old comments — don't add new ones explaining the refactoring.
- NEVER remove code comments unless you can PROVE they are actively false. Comments are important documentation and must be preserved.
- NEVER add comments about what used to be there or how something has changed.

### Jupyter-Style Python Scripts

When the user asks for a "jupyter-style python script", create:

- Simple, minimal Python scripts using `# %%` cell separators for VS Code interactive mode.
- All parameters defined as variables at the top for easy modification.
- No complex abstractions — optimized for hackability and experimentation.
- NEVER use argparse or Fire in these scripts.
- Can be run cell-by-cell interactively or as a complete script.
- Place in the `notebooks/` directory.

#### Example structure
```python
# %%
# Parameters
model_name = "Qwen/Qwen3-32B"
max_tokens = 100
seed = 42

# %%
# Load data and run experiment
...

# %%
# Analyze results
...
```

## Bash rules
- NEVER use `python3 -c` or `python -c` with multiline code (even for plotting scripts). Instead, write the code to a .py file and execute it.
- For one-liners, `python3 -c` is fine.
- Example: instead of `python3 -c "\nimport json\n..."`, write the script to `script.py` and run `python3 script.py`


## Experiment Workflow

### Configuration
- Use YAML config files with Hydra or OmegaConf for all experiments.
- Config files should be complete and self-contained.
- Store configs in `configs/` directory.
- Never hardcode hyperparameters in scripts.
- Most experiment scripts should be run via `uv run script.py /path/to/config.yaml`.
- Create template configs for each new experiment script.

### Reproducibility
- Always set and log the random seed.
- Save the full config alongside results.
- Record: model name, seed, hardware, key hyperparams, wall-clock time, timestamp.

### Results
- Store ALL outputs under `output/` directory.
- Outputs should be stored as JSON files and include timestamp of the experiment in the filename.
- Each experiment gets its own output directory.
- On completion: write a brief report with key findings + suggested next steps.
- On failure: save traceback + diagnosis before moving on.

### Code Organization
- All general reusable code in `src/`.
- Experiment-specific code in `src/experiments/`.
- Plotting code in `src/plot_scripts/`.
- Don't return anything from the main function in Fire scripts.
