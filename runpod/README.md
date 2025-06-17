# RunPod Setup Scripts

This directory contains configuration scripts to quickly set up a new RunPod environment that mirrors your local development setup.

## Quick Start

1. Clone your dotfiles repository in the RunPod:
   ```bash
   git clone https://github.com/yourusername/dotfiles.git
   cd dotfiles/runpod
   ```

2. Make the setup script executable:
   ```bash
   chmod +x setup.sh
   ```

3. Run the setup script with required parameters:
   ```bash
   ./setup.sh -u your_github_username -e your_email@example.com -r https://github.com/yourusername/your-repo.git
   ```

## Script Features

The setup script will:
- ✅ Update system packages
- ✅ Install essential development tools (git, tmux, fish, vim, etc.)
- ✅ Install and configure `uv` as Python package manager
- ✅ Set up SSH keys for GitHub
- ✅ Configure Git with your credentials
- ✅ Set up Fish shell as default with custom configuration
- ✅ Configure tmux with custom settings
- ✅ Install Cursor IDE
- ✅ Install essential Cursor extensions
- ✅ Clone your repository and set up Python virtual environment
- ✅ Install Flash Attention and Jupyter
- ✅ Set up HuggingFace environment variables

## Usage

### Required Arguments
- `-u, --github-username`: Your GitHub username
- `-e, --github-email`: Your GitHub email address
- `-r, --repo-url`: Repository URL to clone (HTTPS or SSH)

### Optional Arguments
- `-k, --ssh-key-type`: SSH key type (default: ed25519)
- `-p, --python-version`: Python version for uv (default: 3.11)
- `-w, --workspace-dir`: Workspace directory (default: /workspace)
- `-c, --cursor-extensions`: Path to cursor extensions file (default: cursor_extensions.txt)
- `-h, --help`: Show help message

### Examples

Basic setup:
```bash
./setup.sh -u johndoe -e john@example.com -r https://github.com/johndoe/myproject.git
```

Custom Python version:
```bash
./setup.sh -u johndoe -e john@example.com -r git@github.com:johndoe/myproject.git --python-version 3.12
```

Custom workspace directory:
```bash
./setup.sh -u johndoe -e john@example.com -r https://github.com/johndoe/myproject.git -w /custom/workspace
```

## Configuration Files

- `setup.sh`: Main setup script
- `ssh_config`: SSH configuration with GitHub setup
- `fish_config.fish`: Fish shell configuration with aliases and functions
- `tmux.conf`: Tmux configuration with custom keybindings and theme
- `cursor_settings.json`: Cursor IDE settings
- `cursor_extensions.txt`: List of Cursor extensions to install

## Post-Setup Steps

After running the setup script:

1. **Add SSH key to GitHub**:
   - The script will display your SSH public key
   - Copy it and add to your GitHub account under Settings → SSH and GPG keys

2. **Test SSH connection**:
   ```bash
   ssh -T git@github.com
   ```

3. **Start using your environment**:
   ```bash
   fish                    # Start Fish shell
   tmux                    # Start tmux session
   cd /workspace/yourproject
   source .venv/bin/activate.fish
   jlab                    # Start Jupyter Lab
   ```

## Environment Variables

The script sets up the following environment variables in `/root/.bashrc`:
- `HF_HOME=/workspace/hf`: HuggingFace cache directory
- `HF_HUB_ENABLE_HF_TRANSFER=1`: Enable faster HF transfers

## Customization

### Adding More Extensions
Edit `cursor_extensions.txt` to add or remove Cursor extensions.

### Modifying Fish Configuration
Edit `fish_config.fish` to customize aliases, functions, and environment variables.

### Updating Tmux Configuration
Edit `tmux.conf` to customize tmux behavior and appearance.

## Troubleshooting

### SSH Key Issues
If you have issues with SSH keys:
```bash
# Check if key exists
ls -la ~/.ssh/

# Test GitHub connection
ssh -T git@github.com

# Regenerate key if needed
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N "" -C "your_email@example.com"
```

### Python Environment Issues
If virtual environment setup fails:
```bash
cd /workspace/yourproject
uv venv --python 3.11
source .venv/bin/activate
uv pip install -r requirements.txt
```

### Cursor Extensions Not Installing
Extensions may fail to install if Cursor server isn't running. You can manually install them later:
```bash
cursor --install-extension extension-name
```

## Notes

- The script is designed for Ubuntu/Debian-based RunPod images
- Root privileges are required for system package installation
- All configurations are stored in `/root/` directory
- The workspace directory defaults to `/workspace` (standard RunPod location)
