---
paths: "**/notebooks/**/*.py"
description: Jupyter-style interactive Python script conventions
---

# Jupyter-Style Python Scripts

When the user asks for a "jupyter-style python script", create:

- Simple, minimal Python scripts using `# %%` cell separators for VS Code interactive mode.
- All parameters defined as variables at the top for easy modification.
- No complex abstractions — optimized for hackability and experimentation.
- NEVER use argparse or Fire in these scripts.
- Can be run cell-by-cell interactively or as a complete script.
- Place in the `notebooks/` directory.

## Example structure
```python
# %%
# Parameters
model_name = "Qwen/Qwen3-32B"
temperature = 0.7
max_tokens = 100
seed = 42

# %%
# Load data and run experiment
...

# %%
# Analyze results
...
```
