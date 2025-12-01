# ==============================================================
# .zshrc
#
# Purpose:
#   Per-shell interactive configuration.
#
# What belongs here:
#   - Runtime environment setup (pyenv, nvm)
#   - Aliases, functions, keybindings
#   - Prompt/theme setup (e.g., Powerlevel10k)
#   - Directory/navigation helpers (zoxide)
#   - fzf integration
#
# What does NOT belong here:
#   - System-level configuration
#   - Setting the default shell
#   - Modifying or creating ~/.zprofile
#   - One-time bootstrap actions
#
# Those belong in setup_shell.sh.
# ==============================================================

# ============================
#  Base Zsh Configuration
# ============================

# Ensure Homebrew environment is loaded (Apple Silicon)
/opt/homebrew/bin/brew shellenv >/dev/null 2>&1
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# ============================
#  Pyenv Initialization
# ============================
if command -v pyenv >/dev/null 2>&1; then
  export PYENV_ROOT="$HOME/.pyenv"
  export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init -)"
fi

# ============================
#  NVM Initialization
#  (must come AFTER pyenv)
# ============================
export NVM_DIR="$HOME/.nvm"
if [[ -s "$(brew --prefix nvm 2>/dev/null)/nvm.sh" ]]; then
  # shellcheck disable=SC1090
  . "$(brew --prefix nvm)/nvm.sh"
fi

# ============================
#  Powerlevel10k Theme
# ============================
if [[ -f "/opt/homebrew/opt/powerlevel10k/powerlevel10k.zsh-theme" ]]; then
  source "/opt/homebrew/opt/powerlevel10k/powerlevel10k.zsh-theme"
fi

# ============================
#  Aliases
# ============================
alias ll="ls -lah"
alias gs="git status"
alias gb="git branch"
alias gc="git commit"
alias gp="git push"

# ============================
#  General Enhancements
# ============================
# zoxide
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# fzf keybindings (if installed)
/opt/homebrew/opt/fzf/install --key-bindings --completion --no-update-rc >/dev/null 2>&1 || true

# ============================
#  Prompt
# ============================
PROMPT='%F{cyan}%n@%m%f:%F{yellow}%~%f$ '
