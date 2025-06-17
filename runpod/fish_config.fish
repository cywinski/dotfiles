# Fish shell configuration for RunPod

# Set environment variables
set -gx EDITOR vim
set -gx PATH $HOME/.local/bin $PATH

# Aliases for convenience
alias ll 'ls -la'
alias la 'ls -A'
alias l 'ls -CF'
alias grep 'grep --color=auto'
alias fgrep 'fgrep --color=auto'
alias egrep 'egrep --color=auto'

# Git aliases
alias gs 'git status'
alias ga 'git add'
alias gc 'git commit'
alias gp 'git push'
alias gl 'git log --oneline'
alias gd 'git diff'

# Python/UV aliases
alias py 'python'
alias pip 'uv pip'
alias venv 'uv venv'

# Tmux aliases
alias tm 'tmux'
alias tma 'tmux attach'
alias tmn 'tmux new-session'

# Jupyter aliases
alias jlab 'jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root'
alias jnb 'jupyter notebook --ip=0.0.0.0 --port=8888 --no-browser --allow-root'

# Custom functions
function mkcd
    mkdir -p $argv[1]
    cd $argv[1]
end

function activate_venv
    if test -d .venv
        source .venv/bin/activate.fish
        echo "Activated virtual environment"
    else
        echo "No .venv directory found"
    end
end

# Auto-activate virtual environment when entering a project directory
function __auto_activate_venv --on-variable PWD
    if test -f .venv/bin/activate.fish
        source .venv/bin/activate.fish
    end
end

# Set up starship prompt if available
if command -v starship >/dev/null 2>&1
    starship init fish | source
end

# Welcome message
echo "🚀 RunPod environment ready!"
echo "💡 Use 'jlab' to start Jupyter Lab"
echo "📁 Current directory: "(pwd)

# Auto-start tmux if not already in tmux and SSH session
if status is-interactive
    and not set -q TMUX
    and set -q SSH_CONNECTION
    exec tmux new-session -A -s main
end
