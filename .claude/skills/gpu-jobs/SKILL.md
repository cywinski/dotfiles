---
name: gpu-jobs
description: Use when an agent needs to run a GPU job (LLM training, inference, eval, any torch workload) on the remote GPU servers h82/h84/h85. Covers scanning free GPUs via nvidia-smi, rsyncing code from the local machine, launching in a detached tmux session with file logging, and monitoring until completion. Can also be invoked with /gpu-jobs.
---

# GPU Jobs on Remote Servers

Spin up and monitor GPU jobs (LLM training, inference, eval) on the three GPU
servers `h82`, `h84`, `h85`. SSH is key-based and non-interactive: `ssh h82
<cmd>` runs one-shot with no password.

## Am I already on a GPU server? (CHECK FIRST)

Before any `ssh hXX ...` call, check whether you are already running on one of
the GPU hosts:

```bash
case "$(hostname -s)" in h82|h84|h85) echo "local=$(hostname -s)";; *) echo "local=mac";; esac
```

- If `local=mac` → behave as the skill describes: `ssh` to every host, `rsync`
  code over, etc.
- If `local=h82|h84|h85` → for THAT host, run commands directly (no `ssh
  <self>`, no `rsync` — the code is already on the local disk). For the OTHER
  two hosts, `ssh` as normal. Skip the rsync step entirely when the launching
  agent is on the same host as the chosen target.

Concrete adjustments when running on a GPU server (call it `$SELF`):
- `nvidia-smi` scan: still fan out to all three, but use a direct local call
  for `$SELF` and `ssh` for the others.
- Code sync: if the target host is `$SELF`, skip rsync. The repo is wherever
  the user already has it; ask if you don't know the path. If the target is a
  different host, rsync from `$SELF` to it as normal.
- `uv sync` / tmux launch / log tail / monitor on `$SELF`: drop the `ssh
  $SELF` wrapper and run the same `bash -lc '...'` (or plain command) locally.

## Server Facts

| Thing              | Value                                              |
| ------------------ | -------------------------------------------------- |
| Hosts              | `h82`, `h84`, `h85`                                |
| Remote code root   | `/home/bcywinski/code/<repo-name>/` (one dir per repo; `<repo-name>` = basename of the local repo dir) |
| Remote datasets    | `/data/bcywinski/` (fast storage; already present on servers — NEVER rsync datasets) |
| Remote logs        | `<remote-code-root>/output/<session>.log`          |
| Python env         | `uv`, per-project venv. Always `uv sync` then `uv run <cmd>` from the repo root. |
| GPU selection      | `CUDA_VISIBLE_DEVICES=<ids>` env var (e.g. `0,1`)  |
| Job runner         | detached `tmux` session, stdout/stderr teed to a log file |

### Remote shell & PATH (IMPORTANT)

`uv` is installed at `~/.local/bin/uv` on all hosts but is **only on PATH for login shells**. Non-interactive `ssh <host> <cmd>` does NOT source `.bashrc`, so bare `uv` will be "command not found".

- **One-shot SSH commands that call `uv`** → wrap in a login shell:
  ```bash
  ssh <host> "bash -lc 'cd /home/bcywinski/code/<repo> && uv sync'"
  ```
- **Commands that only use `nvidia-smi`, `tmux`, `tail`, `cat`, `grep`, `mkdir`, `rm`** → no login shell needed (these are on the default PATH).
- **The tmux launcher script** runs as a non-login shell, so it MUST export PATH itself (see the launcher template in step 4a).

### Default GPU count (when to occupy multiple GPUs)

Default to multi-GPU **only when it will notably speed up the run**; otherwise single-GPU. Idle GPUs are not a reason to grab them — hogging cluster capacity has an opportunity cost for your other jobs. Decision rule:

| Workload                                              | Default N                         | Why                                                                                                                    |
| ----------------------------------------------------- | --------------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| **Training** (full FT, LoRA, SFT, RL) — real run      | `min(4, free_on_chosen_host)`     | DDP gives near-linear speedup to ~4 GPUs; past that comms overhead dominates and you hog capacity for little gain.    |
| **Training — smoke test / debug / dev iteration**     | 1                                 | Fast startup, errors surface quicker, don't waste GPUs on a run you'll kill in 30s.                                    |
| **Inference / serving / single-sample generation**    | 1                                 | One GPU usually saturates; multi-GPU only helps if the model doesn't fit (then it's TP — necessity, not a speedup).    |
| **Eval on a large batched set**                       | `min(2, free)`                    | Only if the eval script explicitly shards the dataset across GPUs (DDP eval). Otherwise 1.                             |
| **Model doesn't fit on one GPU**                      | as many as needed to fit (TP/ZeRO) | Necessity, not a speedup choice — pick N so the model+optimizer state fit across N GPUs.                              |

**Before defaulting to N>1, verify the launch script actually supports multi-GPU.** If the repo's train/eval script wasn't written for `torchrun`/`accelerate`/DDP, wrapping it in torchrun will either no-op (script ignores `LOCAL_RANK`) or error. Check the script for `init_process_group` / `LocalRank` / `accelerate.Accelerator` usage; if unsure, ask the user rather than guessing.

**Cap at 4 by default** even if more are free — diminishing returns past 4 for most LLM training on these hosts, and it leaves capacity for your other jobs. The user can override by stating N explicitly.

When the user explicitly states N, **always honor it** — the heuristic is only a default for when they didn't specify.

## Required Inputs

Before starting, the calling task MUST supply (ask if any are missing):

1. **Local repo path** — the directory on this Mac to rsync from (usually the current working dir).
2. **Launch command** — the script + args/config the job runs, e.g. `uv run python src/train.py configs/exp.yaml`. Hydra/OmegaConf configs are passed as paths, never hardcoded hyperparams.
3. **GPU count N** — see *Default GPU count* above. If the user didn't specify, infer N from the workload per the heuristic; if the workload type is ambiguous or the script's multi-GPU support is unclear, ask.
4. **Min free VRAM per GPU (MiB)** — optional; default pick the freest GPUs regardless.

## Subcommands

Invoke as `/gpu-jobs <subcommand> [args]`. With no subcommand, defaults to `launch`.

| Subcommand                    | Purpose                                              | Workflow steps |
| ----------------------------- | ---------------------------------------------------- | -------------- |
| `scan [N]`                    | Report free GPUs on all 3 hosts + suggested pick     | 1              |
| `launch`                      | Full job: scan → rsync → uv sync → tmux+log → monitor | 1–5           |
| `list`                        | Show all running tmux jobs across hosts              | 6              |
| `logs <host> <session>`       | Tail a job's log                                     | 5 (log tail)   |
| `monitor <host> <session>`    | Poll a running job until completion, report status   | 5              |
| `kill <host> <session>`       | Stop a job — REQUIRES USER APPROVAL                  | 7              |

### `/gpu-jobs scan [N]`
Run step 1. Print the full GPU table (host, index, mem.free, mem.total, util) for all 3 hosts. If `N` (GPU count) is given or inferred from context, also print the recommended host + `CUDA_VISIBLE_DEVICES` per the selection algorithm. No state change — safe to run anytime.

### `/gpu-jobs launch`
The default. Runs steps 1–5 end to end. Gather the Required Inputs above — inferring GPU count N from the *Default GPU count* heuristic when the user didn't specify, asking only if workload type or multi-GPU support is unclear — then: scan → rsync → `uv sync` → write+scp launcher → tmux start → monitor until done. Report final status (success/failed + EXIT_CODE), key metrics from the log tail, and the log path.

### `/gpu-jobs list`
Run step 6. Lists `tmux ls` across h82/h84/h85 in parallel. For each live session, also show the reserved GPUs by grepping `CUDA_VISIBLE_DEVICES=` from the matching log file under `output/`.

### `/gpu-jobs logs <host> <session>`
```bash
ssh <host> "tail -n 50 /home/bcywinski/code/<repo>/output/<session>.log"
```
Increase the line count if the user asks (e.g. `logs h82 train-exp1-... 200`). `<repo>`: infer from the session-name prefix if it matches the `<job>` convention; otherwise ask. For a live follow, the user can run `ssh <host> "tail -f .../output/<session>.log"` in their own terminal — point them at the path rather than holding an open pipe from the agent.

### `/gpu-jobs monitor <host> <session>`
Run step 5's poll loop on an already-running job (launched by this skill or pre-existing). Poll at the standard cadence (~30s first, then every few minutes), report progress (step/loss/ETA from the log), detect completion via `EXIT_CODE=` line or session-gone, then report final status + log path.

### `/gpu-jobs kill <host> <session>`
Run step 7. **Ask the user for explicit approval before doing anything destructive** — this is the only approval-gated action. On approval: `tmux kill-session -t '<session>'`, then verify the reserved GPUs are clear and report any lingering PIDs. Ask before `kill`-ing lingering processes too — do not kill unilaterally.

## Workflow

### 1. Scan free GPUs across all servers

Run this from the local machine (it fans out to all 3 hosts in parallel):

```bash
for h in h82 h84 h85; do
  ssh "$h" nvidia-smi --query-gpu=index,memory.free,memory.total,utilization.gpu --format=csv,noheader,nounits 2>/dev/null | sed "s/^/$h /" &
done; wait
```

Output (one line per GPU, whitespace-tolerant CSV):
```
h82 0, 22000, 24000, 4
h82 1, 23800, 24000, 0
h84 0, 24000, 24000, 0
...
```

Columns: `host index, memory.free(MiB), memory.total(MiB), gpu_util(%)`.

**Selection algorithm** (single-node only — never split one job across hosts):

- For each host, sort its GPUs by `memory.free` descending.
- Take the top-`N` GPUs of that host; compute their summed free memory.
- Pick the host whose top-`N` sum is largest AND every one of those `N` GPUs meets the min-free-VRAM requirement (if given).
- `CUDA_VISIBLE_DEVICES` = the comma-joined indices of those top-`N` GPUs (preserve their original index values, do not renumber).
- Tie-break: prefer the lower host name (`h82` > `h84` > `h85`).

If no host has `N` sufficiently-free GPUs, STOP and report the scan table to the user — do not launch on contended GPUs.

### 2. rsync code to the chosen server

`<repo>` = basename of the local repo path. Sync from local to
`<host>:/home/bcywinski/code/<repo>/`. Exclude heavy/regenerable dirs; keep
`.env` (needed by `load_dotenv()`); never sync datasets (they live in
`/data/bcywinski/` on the server).

```bash
rsync -azh --delete \
  --exclude='.venv/' --exclude='output/' --exclude='.git/' \
  --exclude='__pycache__/' --exclude='data/' --exclude='*.pyc' \
  --exclude='.ruff_cache/' \
  --include='.env' \
  -e ssh \
  <local-repo-path>/ <host>:/home/bcywinski/code/<repo>/
```

Notes:
- `--delete` keeps the remote mirror in sync; safe because `output/` is excluded (remote logs/results are preserved).
- Trailing slashes matter: `<local-path>/` (contents) → `<remote>/` (dir).
- If a new dependency was added locally, it will be installed in step 3 via `uv sync`.

### 3. Sync deps on the server

```bash
ssh <host> "bash -lc 'cd /home/bcywinski/code/<repo> && uv sync'"
```

If the job needs a package not yet in `pyproject.toml`, add it locally with
`uv add <pkg>` (per global rules — never edit `pyproject.toml` by hand), then
re-rsync and `uv sync` again. Installing packages is autonomous (no approval needed).

### 4. Launch in tmux with logging

To avoid nested-shell quoting bugs, generate a small launcher script locally,
scp it to the server, and run it inside tmux. Build the script with the actual
values filled in — no placeholders.

**Session + log naming** (timestamp = `date +%Y%m%d-%H%M%S`, UTC):
- session: `<job>-<timestamp>` (e.g. `train-exp1-20260620-141230`)
- log: `/home/bcywinski/code/<repo>/output/<session>.log`

#### 4a. Write the launcher locally

Write to a local temp file, e.g. `/tmp/launch_<session>.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
export PATH="$HOME/.local/bin:$PATH"
cd /home/bcywinski/code/<repo>
mkdir -p output
export CUDA_VISIBLE_DEVICES=<ids>
# plus any other env exports the job needs (e.g. HF_TOKEN from the server env)
<LAUNCH_COMMAND> 2>&1 | tee output/<session>.log
echo "EXIT_CODE=${PIPESTATUS[0]}" | tee -a output/<session>.log
```

`<LAUNCH_COMMAND>` depends on GPU count:

- **Single-GPU (N=1):** `uv run python src/train.py configs/exp.yaml`
- **Multi-GPU, torchrun (N>1):** `uv run torchrun --nproc_per_node=<N> --master_port=29500 src/train.py configs/exp.yaml`
- **Multi-GPU, accelerate (N>1):** `uv run accelerate launch --multi_gpu --num_processes=<N> src/train.py configs/exp.yaml`

Use a `--master_port` that's unlikely to clash (e.g. `29500 + (gpu_index_sum % 100)`) if you might run multiple torchrun jobs on the same host. Pick the launch backend that the repo already uses; if unsure, ask the user.

#### 4a-bis. Serve-and-drive pattern (inference/eval against a local server)

Many inference/eval jobs are two-stage: start a model server (e.g. vLLM
`api_server`) in the background, wait for it to be ready, then run a **driver**
script (an OpenAI client) against it. The single-`<LAUNCH_COMMAND>` template
above does NOT fit this — and the classic mistake is redirecting only the
server to a log while the driver prints to the (detached) tmux pane, leaving
you blind to the actual experiment's progress.

Rule: the **driver's** stdout+stderr MUST be teed to the session log
(`output/<session>.log`). Keep the server's verbose log in a SEPARATE file so
the session log stays focused on experiment progress. Tensor-parallel: pick N
so the model fits, and make sure `num_attention_heads` and `num_kv_heads` are
divisible by N.

```bash
#!/usr/bin/env bash
set -euo pipefail
export PATH="$HOME/.local/bin:$PATH"
cd /home/bcywinski/code/<repo>
mkdir -p output
export CUDA_VISIBLE_DEVICES=<ids>
export CUDA_DEVICE_ORDER=PCI_BUS_ID
PORT=<port>
SERVER_LOG="output/vllm_<session>.log"

# 1. server in background -> its own verbose log
uv run python -m vllm.entrypoints.openai.api_server \
  --model "<model>" --tensor-parallel-size <N> --dtype bfloat16 \
  --max-model-len <len> --port "$PORT" --enforce-eager \
  > "$SERVER_LOG" 2>&1 &
SERVER_PID=$!

# 2. wait for readiness (teed to the SESSION log so you can watch it)
{
  for i in $(seq 1 600); do
    curl -s "http://localhost:$PORT/v1/models" >/dev/null 2>&1 && { echo "server ready after ${i}0s"; break; }
    kill -0 $SERVER_PID 2>/dev/null || { echo "SERVER DIED"; tail -40 "$SERVER_LOG"; exit 1; }
    sleep 10
  done
  # 3. driver -> tee to session log (THIS is the experiment output you monitor)
  uv run python -m src.experiments.run_inference --vllm_url "http://localhost:$PORT" <args>
} 2>&1 | tee output/<session>.log
RC=${PIPESTATUS[0]}

kill $SERVER_PID 2>/dev/null || true
echo "EXIT_CODE=$RC" | tee -a output/<session>.log
exit $RC
```

Now `tail -f output/<session>.log` shows readiness + per-item driver progress,
and `output/vllm_<session>.log` holds the server internals for post-mortem.

#### 4b. Ship and start it

```bash
# ensure remote output dir exists (it's excluded from rsync)
ssh <host> "mkdir -p /home/bcywinski/code/<repo>/output"
# copy the launcher to the server
scp /tmp/launch_<session>.sh <host>:/tmp/launch_<session>.sh
# start detached tmux session running the launcher (session ends when the job exits)
ssh <host> "tmux new-session -d -s '<session>' 'bash /tmp/launch_<session>.sh'"
```

The tmux session terminates as soon as the launcher script returns, so
`tmux has-session` is a clean completion signal (see step 5). The log file is
the persistent record for post-mortem — no need to keep the pane alive.

### 5. Monitor periodically

After launch, poll until the job finishes. Suggested cadence: first check at
~30s (confirm it actually started and isn't erroring immediately), then every
few minutes. Each poll:

```bash
# is the tmux session still alive? (gone => job ended)
ssh <host> "tmux has-session -t '<session>' 2>/dev/null && echo RUNNING || echo ENDED"

# recent log lines
ssh <host> "tail -n 50 /home/bcywinski/code/<repo>/output/<session>.log"

# GPU activity on the reserved GPUs (quick sanity that work is happening)
ssh <host> "nvidia-smi --query-gpu=index,memory.used,utilization.gpu --format=csv,noheader -i <ids>"
```

**Completion detection** — the job is done when the `tmux has-session` check reports `ENDED` (the launcher returned and the session terminated). Then read the `EXIT_CODE=` line from the log to determine success vs failure:
- `EXIT_CODE=0` → success; report final metrics/last lines + log path.
- non-zero → failure; report the tail (especially the traceback) and the log path. Do NOT blindly retry — diagnose root cause first (global rule).

As a fallback if the session was killed externally (no `EXIT_CODE=` line), check the reserved GPUs: ~0 MiB used and 0% util across consecutive polls confirms the job is gone.

While monitoring, report progress to the user (current step/loss/ETA if visible in the log) at a reasonable interval, not every poll.

### 6. List running jobs

```bash
for h in h82 h84 h85; do
  echo "== $h =="
  ssh "$h" "tmux ls 2>/dev/null" &
done; wait
```

To see what's actually on the GPUs (PIDs + mem) on a host:
```bash
ssh <host> "nvidia-smi --query-compute-apps=gpu_uuid,pid,used_memory --format=csv,noheader"
```

### 7. Kill a job — ASK THE USER FIRST

Killing any process or tearing down a tmux session REQUIRES explicit user
approval (the only action that does). Everything else (rsync, uv sync/add,
launch, read, monitor) is autonomous.

After approval:
```bash
ssh <host> "tmux kill-session -t '<session>'"
```
This kills the launcher and (because torchrun/accelerate forward signals to
children) the GPU processes. Verify they're gone:
```bash
ssh <host> "nvidia-smi --query-compute-apps=pid,used_memory --format=csv,noheader"
```
If GPU procs linger after the session is killed, report the PIDs to the user
and ask before `kill`-ing them — do not kill unilaterally.

## Conventions & Rules

- **Seeds & reproducibility**: the job script must set and log its seed; the launch command should pass a `seed=` via the config, not hardcode it. (Global rule.)
- **Outputs**: all results/logs go under `output/` on the server with timestamps in filenames. (Global rule.)
- **Configs**: Hydra/OmegaConf YAML under `configs/`; pass paths on the CLI, never hardcode hyperparams in the launch command.
- **Env vars**: the Python code reads secrets from `.env` via `load_dotenv()`. `.env` is rsync'd; never hardcode keys.
- **Datasets**: reference `/data/bcywinski/<dataset>` in configs; do not rsync data.
- **Fail fast**: if the scan finds no free GPUs, or `uv sync` fails, or the job dies immediately, STOP and report — do not paper over failures.
- **One job per tmux session**; never reuse a live session name (timestamp makes collisions impossible).
- **Keep `CUDA_VISIBLE_DEVICES` indices as the GPU's real `index` from nvidia-smi** — torchrun/accelerate renumber internally; do not pre-renumber.
