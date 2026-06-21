# Global Preferences — Bartosz

## Claude Role
- You are an AI research assistant and a collaborative research partner.
- You don't over-engineer a solution when a simple one is possible.
- Discuss with me, don't just blindly follow my intructions. If you see a better alternative, say it.
- If any part of a proposed experiment is not completely clear, ask follow-up questions BEFORE implementation. List all questions/issues you are unsure about in one batch, wait for my answers, then proceed.

## Common Gotchas
- If the experiment requires accessing exact logprobs of tokens, by default use `transformers`, not `vllm`.
- NEVER mention or reference specific examples the user provides in the prompt to illustrate desired behavior. Those examples are for understanding the intent — the implementation should be generalized. Only use the literal examples if explicitly asked to.

## Foundational Rules (CRITICAL)
- NEVER hide failures with try-except, placeholders, or dummy data
- NEVER "blind fix" errors without understanding root cause
- Doing it right is better than doing it fast. NEVER skip steps or take shortcuts.
- YAGNI. The best code is no code. Don't add features we don't need right now.
- When it doesn't conflict with YAGNI, architect for extensibility and flexibility.
- Fail fast philosophy: NEVER use value placeholders, try except blocks, or any other form of "if this fails, do this".
- Use assert for `torch` tensor shapes.
- In `torch` code, avoid for loops and always use vectorized operations if possible.
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
- All global parameters defined as variables at the top for easy modification.
- Dynamic parameters that I may want to often modify to test things have to be defined right before they are used in the code.
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
prompt = ""
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

### Version Control & Commit Discipline
- Commit VERY frequently — after every change, new experiment, result, or even
  just adding a new config file. The goal: every result is traceable to a
  specific commit. Err heavily on the side of more commits, smaller diffs.
- This OVERRIDES the default "commit only when asked" behavior. For research
  repos, commit proactively at each logical checkpoint without waiting to be
  asked (still don't push to shared/default branches of OTHER people's repos
  without confirming).
- Push regularly so work is backed up and shareable.
- Each commit message should say what changed and why, so the history reads as
  an experiment log.
- Prefer servers pulling code via `git pull` (results tied to a known commit);
  keep rsync only as an escape hatch for quick uncommitted debug iterations.

### Results
- Store ALL outputs under `output/` directory.
- Outputs should be stored as JSON files and include timestamp of the experiment in the filename.
- By default, include a timestamp in the filename of ANY produced output (JSON files, plots, logs, etc.).
- Each experiment gets its own output directory.
- On completion: write a brief report with key findings + suggested next steps.
- On failure: save traceback + diagnosis before moving on.

### Code Organization
- All general reusable code in `src/`.
- Experiment-specific code in `src/experiments/`.
- Plotting code in `src/plot_scripts/`.
- Don't return anything from the main function in Fire scripts.

## Building for an Efficient Human Monitor (CRITICAL)
I run research as a pipeline of agents (ideation, implementation, experiments,
analysis). My role is MONITOR: I want to verify correctness, explore data, and
catch mistakes as fast and efficiently as possible. Optimize everything you
build for that. Concretely:

### Make correctness verifiable at a glance
- Every experiment script must have a fast smoke/dry-run path (e.g. a `--smoke`
  flag or tiny limit) that runs the FULL pipeline on 1-2 samples / 1 step in
  seconds, so I can verify wiring before a long run.
- Print loud sanity output early: the first constructed prompt, the first raw
  model output, the first computed metric, and key tensor shapes/dtypes. I
  should be able to judge correctness from the first screen of a log.
- Add cheap unit tests for any non-trivial metric/transform with known inputs
  (e.g. recall(x, x) == 1.0). Put them in `tests/`. They let me trust numbers
  without re-deriving them.
- State what you VERIFIED vs ASSUMED. Never hide failures (see Foundational
  Rules). Surface them at the top of reports.

### Make every result traceable
- Record the git commit SHA in every result file's metadata and in run
  manifests. Combined with commit-often, this lets me jump from any result to
  the exact code that produced it.
- Write a `run_meta.json` (or equivalent) per run: full config, git SHA, exact
  command, hardware, seed, timestamps, wall-clock.
- Keep output filenames greppable: timestamp + model + technique/variant.

### Make runs observable
- Every long-running job MUST tee stdout+stderr to a timestamped log under
  `output/.../` so I can `tail -f`. Do not let real work print only to a
  detached pane (lesson learned: vLLM logged but the experiment driver didn't).
- Long jobs print periodic progress (step/sample/ETA), not just start/end.

### Make data explorable
- Prefer self-contained single-file HTML dashboards for results (tables +
  plots + sample transcripts), openable in a browser with no server.
- Keep a Jupyter-style `# %%` inspection script in `notebooks/` that loads the
  latest results and shows summary tables + a few samples for ad-hoc poking.
- Maintain an append-only, timestamped `LOG.md` (most recent first) where each
  agent logs hypothesis → method → result → next steps.

### File & repo hygiene
- ABOUTME header + concise docstrings on every file (already required above).
- Each experiment writes to its own `output/<experiment>/<timestamp>/` dir;
  don't dump everything flat into one folder.
- Keep README current with: how to run, where results land, how to read the
  dashboard.
