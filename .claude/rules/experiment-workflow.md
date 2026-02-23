---
description: Experiment design and execution protocol
---

# Experiment Workflow

## Configuration
- Use YAML config files with Hydra or OmegaConf for all experiments.
- Config files should be complete and self-contained.
- Store configs in `configs/` directory.
- Never hardcode hyperparameters in scripts.
- Most experiment scripts should be run via `uv run script.py /path/to/config.yaml`.
- Create template configs for each new experiment script.

## Reproducibility
- Always set and log the random seed.
- Save the full config alongside results.
- Record: model name, seed, hardware, key hyperparams, wall-clock time, timestamp.

## Results
- Store ALL outputs under `output/` directory.
- Outputs should be stored as JSON files and include timestamp of the experiment in the filename.
- Each experiment gets its own output directory.
- On completion: write a brief report with key findings + suggested next steps.
- On failure: save traceback + diagnosis before moving on.

## Code Organization
- All general reusable code in `src/`.
- Experiment-specific code in `src/experiments/`.
- Plotting code in `src/plot_scripts/`.
- Don't return anything from the main function in Fire scripts.
