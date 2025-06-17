# RunPod Minimal Setup Scripts

Minimal configuration scripts for RunPod that only set up **non-persistent, pod-wide configurations**. Since `/workspace` is preserved between pod restarts, this setup focuses only on system-level configurations that need to be recreated each time.

Inspired by [cadentj/dotfiles](https://github.com/cadentj/dotfiles/tree/main).

## Quick Start

### One-liner (easiest):
```bash
curl -fsSL https://raw.githubusercontent.com/cywinski/dotfiles/main/runpod/install.sh | bash
```

### Alternative one-liner (if raw URL fails):
```bash
git clone https://github.com/cywinski/dotfiles.git /tmp/dotfiles && cd /tmp/dotfiles/runpod && ./setup.sh
```

### Manual setup:
```bash
git clone https://github.com/cywinski/dotfiles.git
cd dotfiles/runpod
./setup.sh
```

## What Gets Configured

### ✅ System Dependencies
- Essential packages (curl, wget, git, build tools)
- Python development tools
- **uv** package manager

### ✅ Environment Variables
- `HF_HOME=/workspace/hf` (HuggingFace cache in persistent storage)
- `HF_HUB_ENABLE_HF_TRANSFER=1` (faster HF transfers)
- `PATH` updated for uv
- **VSCode/Cursor persistence:**
  - `VSCODE_EXTENSIONS=/workspace/.vscode-server/extensions`
  - `VSCODE_USER_DATA_DIR=/workspace/.vscode-server/data`
  - `CURSOR_USER_DATA_DIR=/workspace/.cursor-server/data`
  - `CURSOR_EXTENSIONS_DIR=/workspace/.cursor-server/extensions`
- **Cache directories:**
  - `npm_config_cache=/workspace/.npm`
  - `PIP_CACHE_DIR=/workspace/.pip-cache`
  - `UV_CACHE_DIR=/workspace/.uv-cache`

### ✅ SSH & GitHub
- SSH key generation (ed25519)
- Git configuration (username, email)
- SSH config for GitHub

## What's NOT Included (Since /workspace is Persistent)

- ❌ Virtual environments (create these in `/workspace/projects`)
- ❌ Cursor IDE installation
- ❌ Development tools like tmux/fish (use `first_time_setup.sh` for these)
- ❌ Project-specific dependencies
- ❌ Repository cloning

## First-Time Workspace Setup

For your first RunPod setup, also run the workspace installer to get persistent development tools:

```bash
./first_time_setup.sh
```

This installs to `/workspace` (persistent):
- **tmux** - Terminal multiplexer
- **fish** - Modern shell with auto-completion (set as default)
- Configuration files and aliases

## Modular Scripts

- `setup.sh` - Main orchestrator script (run every time)
- `install_system.sh` - System package installation
- `setup_env.sh` - Environment variables and directories
- `setup_github.sh` - SSH keys and Git configuration
- `first_time_setup.sh` - **One-time setup** for persistent tools in `/workspace`

## Configuration

Edit the default values in `setup.sh`:
```bash
GITHUB_USERNAME="${GITHUB_USERNAME:-cywinski}"
GITHUB_EMAIL="${GITHUB_EMAIL:-bcywinski11@gmail.com}"
SSH_KEY_TYPE="${SSH_KEY_TYPE:-ed25519}"
```

Or set environment variables:
```bash
export GITHUB_USERNAME="your_username"
export GITHUB_EMAIL="your_email@example.com"
./setup.sh
```

## Post-Setup Workflow

1. **Add SSH key to GitHub** (displayed after setup)
2. **First-time only**: Install persistent tools to `/workspace`:
   ```bash
   ./first_time_setup.sh
   ```
3. **Clone your projects to `/workspace`**:
   ```bash
   cd /workspace/projects
   git clone git@github.com:cywinski/yourproject.git
   cd yourproject
   ```
4. **Set up project environment**:
   ```bash
   uv venv
   source .venv/bin/activate
   uv pip install -r requirements.txt
   ```

## Why Minimal?

RunPod pods preserve `/workspace` between restarts, so there's no need to reinstall:
- Development tools (can be installed to `/workspace`)
- Project dependencies (virtual environments in `/workspace`)
- Configuration files (store in `/workspace`)

This approach:
- ⚡ **Faster setup** (only essential system configs)
- 💾 **Preserves work** (everything important in `/workspace`)
- 🔄 **Repeatable** (run anytime without conflicts)

## Troubleshooting

### SSH Key Issues
```bash
# Check key exists
ls -la ~/.ssh/
# Test GitHub connection
ssh -T git@github.com
```

### Environment Variables Not Available
```bash
# Reload bashrc
source ~/.bashrc
# Or start new shell
bash
```

## Example Workflow

1. Start new RunPod
2. Run setup: `curl -fsSL https://raw.githubusercontent.com/cywinski/dotfiles/main/runpod/install.sh | bash`
3. Add SSH key to GitHub
4. Clone projects: `cd /workspace && git clone ...`
5. Work normally - everything persists in `/workspace`
