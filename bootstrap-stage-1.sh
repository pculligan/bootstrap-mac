#!/opt/homebrew/bin/bash

set -eo pipefail

echo "================ DEBUG: Stage-1 Shell Environment ================"
echo "ps -p $$ -o comm=        => $(ps -p $$ -o comm=)"
echo "Real BASH executable     => ${BASH:-"(undefined)"}"
echo "Value of \$0             => $0"
echo "Command: which bash       => $(which bash)"
echo "Command: bash --version   => $(bash --version | head -n1 2>/dev/null)"
echo "Command: /bin/bash --ver  => $(/bin/bash --version | head -n1 2>/dev/null)"
echo "Command: /opt/homebrew/bin/bash --ver => $(/opt/homebrew/bin/bash --version | head -n1 2>/dev/null)"
echo "-------------------------------------------------------------------"
echo ""

# Parse --config argument (path to JSON)
CONFIG_JSON=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --config)
      CONFIG_JSON="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

if [[ -z "$CONFIG_JSON" ]]; then
  err "No --config <file.json> supplied. Stage 1 requires a configuration file."
  exit 1
fi

# =============================================================================
# Unified Bootstrap — JSON Driven
# =============================================================================

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# CONFIG_DIR="$ROOT_DIR/config"
# CONFIG_JSON="$CONFIG_DIR/bootstrap-config.json"
LOG_DIR="$ROOT_DIR/logs"
mkdir -p "$LOG_DIR"

log(){ echo "[bootstrap] $*"; }
warn(){ echo "[warn] $*"; }
err(){ echo "[error] $*"; }

# Ensure jq installed (required for JSON parsing)
if ! command -v jq >/dev/null 2>&1; then
  err "jq is required but not installed. Install via: brew install jq"
  exit 1
fi

# Helper to extract JSON arrays
json_list() {
  local key="$1"
  jq -r ".$key[]?" "$CONFIG_JSON" 2>/dev/null || true
}

# =============================================================================
# install_tools()
# =============================================================================
install_tools() {
  log "Installing CLI tools..."

  json_list tools | while IFS= read -r p; do
    p="${p-}"
    [[ -z "$p" ]] && continue

    if brew list "$p" >/dev/null 2>&1; then
      log "Updating $p..."
      brew upgrade "$p" || true
    else
      log "Installing $p..."
      brew install "$p" || true
    fi
  done
}

# =============================================================================
# install_langs()
# =============================================================================
install_langs() {
  log "Installing language runtimes..."

  # Runtime managers (brew-installed)
  json_list runtime_managers | while IFS= read -r mgr; do
    mgr="${mgr-}"
    [[ -z "$mgr" ]] && continue

    if brew list "$mgr" >/dev/null 2>&1; then
      log "Updating $mgr..."
      brew upgrade "$mgr" || true
    else
      log "Installing $mgr..."
      brew install "$mgr" || true
    fi
  done

  # Python version from JSON
  PY_VERSION="$(jq -r '.python_version // "3.14"' "$CONFIG_JSON")"

  # Ensure pyenv is initialized before using it
  export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"
  export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init -)"

  if command -v pyenv >/dev/null 2>&1; then
    if ! pyenv versions --bare | grep -q "^$PY_VERSION"; then
      log "Installing Python $PY_VERSION via pyenv..."
      pyenv install -s "$PY_VERSION"
    fi
    pyenv global "$PY_VERSION"
  fi

  # Node version from JSON (via nvm)
  NODE_VERSION="$(jq -r '.node_version // "lts"' "$CONFIG_JSON")"
  export NVM_DIR="$HOME/.nvm"
  if [[ -s "$(brew --prefix nvm)/nvm.sh" ]]; then
    . "$(brew --prefix nvm)/nvm.sh"
  fi
  if command -v nvm >/dev/null 2>&1; then
    if [[ "$NODE_VERSION" == "lts" ]]; then
      log "Installing Node (LTS)..."
      nvm install --lts
      nvm alias default 'lts/*'
      nvm use default
    else
      log "Installing Node ($NODE_VERSION)..."
      nvm install "$NODE_VERSION"
      nvm alias default "$NODE_VERSION"
      nvm use default
    fi
  fi
}

# =============================================================================
# install_apps()
# =============================================================================
install_apps() {
  log "Installing GUI applications..."

  json_list apps | while IFS= read -r app; do
    app="${app-}"
    [[ -z "$app" ]] && continue

    if brew list --cask "$app" >/dev/null 2>&1; then
      brew upgrade --cask "$app" || true
    else
      brew install --cask "$app" || true
    fi
  done
}

# =============================================================================
# setup_shell()
# =============================================================================
setup_shell() {
  log "Configuring shell..."
  ZPROFILE="$HOME/.zprofile"
  touch "$ZPROFILE"

  # brew shellenv
  if ! grep -q 'brew shellenv' "$ZPROFILE"; then
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$ZPROFILE"
  fi

  # PATH
  if ! grep -q '/opt/homebrew/bin' "$ZPROFILE"; then
    echo 'export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"' >> "$ZPROFILE"
  fi

  # Login shell
  if [[ "$SHELL" != "/bin/zsh" ]]; then
    chsh -s /bin/zsh || true
  fi
}

# =============================================================================
# setup_dotfiles() — fetch from public repo
# =============================================================================
setup_dotfiles() {
  log "Fetching and installing dotfiles from public repo..."

  DOTFILES_URL_BASE="https://raw.githubusercontent.com/pculligan/bootstrap-mac/main/dotfiles"
  TARGETS=(.zshrc .gitconfig .gitignore_global)

  for f in "${TARGETS[@]}"; do
    src_url="$DOTFILES_URL_BASE/$f"
    dest="$HOME/$f"

    echo "⬇️  Downloading $f from $src_url"
    curl -fsSL "$src_url" -o "$dest.tmp" || {
      warn "Failed to download $f — skipping."
      continue
    }

    # Backup existing file if present and not a symlink
    if [[ -e "$dest" && ! -L "$dest" ]]; then
      backup="${dest}.backup-$(date +%Y%m%d%H%M%S)"
      mv "$dest" "$backup"
      echo "📦 Backed up existing $f to $backup"
    fi

    mv "$dest.tmp" "$dest"
    chmod 644 "$dest"
    echo "✔ Installed $f"
  done
}

# =============================================================================
# setup_git()
# =============================================================================
setup_git() {
  log "Configuring Git..."
  git config --global init.defaultBranch main
  git config --global pull.rebase false
  git config --global push.default current
  git config --global core.editor "code --wait"
  git config --global color.ui auto
  git config --global core.excludesfile "$HOME/.gitignore_global"
  git config --global fetch.prune true
}

# =============================================================================
# setup_vscode()
# =============================================================================
setup_vscode() {
  log "Installing VSCode extensions..."
  if ! command -v code >/dev/null 2>&1; then
    warn "VS Code CLI not available."
    return
  fi

  json_list vscode_extensions | while IFS= read -r ext; do
    ext="${ext-}"
    [[ -z "$ext" ]] && continue

    if ! code --list-extensions | grep -qx "$ext"; then
      code --install-extension "$ext" || true
    fi
  done
}

# =============================================================================
# setup_python()
# =============================================================================
setup_python() {
  log "Installing global Python packages..."

  if ! command -v pyenv >/dev/null 2>&1; then
    warn "pyenv missing — skipping."
    return
  fi

  export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"
  export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init -)"

  PIP_BIN="$(pyenv which pip3)"
  json_list python | while IFS= read -r pkg; do
    pkg="${pkg-}"
    [[ -z "$pkg" ]] && continue
    "$PIP_BIN" install "$pkg"
  done
}

# =============================================================================
# setup_node()
# =============================================================================
setup_node() {
  log "Installing global Node packages..."

  export NVM_DIR="$HOME/.nvm"
  if [[ -s "$(brew --prefix nvm)/nvm.sh" ]]; then
    . "$(brew --prefix nvm)/nvm.sh"
  fi

  if ! command -v nvm >/dev/null 2>&1; then
    warn "nvm missing — skipping."
    return
  fi

  NPM_BIN="$(dirname "$(nvm which current)")/npm"
  json_list node | while IFS= read -r pkg; do
    pkg="${pkg-}"
    [[ -z "$pkg" ]] && continue
    "$NPM_BIN" install -g "$pkg"
  done
}

# =============================================================================
# GitHub Scope Helper
# =============================================================================
ensure_gh_scope() {
  local host="$1"
  local scope="admin:public_key"

  echo "🔎 Checking GitHub OAuth scopes for $host…"

  # Get scopes for the host
  local scopes
  scopes="$(gh auth status --hostname "$host" --json scopes -q '.scopes[]' 2>/dev/null | tr '\n' ' ' || true)"

  if [[ "$scopes" =~ $scope ]]; then
    echo "✔ $host already has required scope: '$scope'"
    return 0
  fi

  echo "⚠️ '$scope' scope missing for $host — requesting now…"
  gh auth refresh -h "$host" -s "$scope" || {
    echo "❌ Failed to obtain '$scope' scope for $host"
    return 1
  }

  echo "✔ Scope '$scope' granted for $host"
}

# =============================================================================
# setup_ssh()
# =============================================================================
setup_ssh() {
  local mode="$1"
  local DEVICE_NAME="$2"

  echo "🔐 Setting up SSH identities..."
  echo "💻 Device: $DEVICE_NAME"

  local SSH_DIR="$HOME/.ssh"
  mkdir -p "$SSH_DIR"
  chmod 700 "$SSH_DIR"

  local SSH_CONFIG="$SSH_DIR/config"
  [[ ! -f "$SSH_CONFIG" ]] && touch "$SSH_CONFIG"
  chmod 600 "$SSH_CONFIG"

  ensure_key() {
    local LABEL="$1"          # personal or corp
    local HOST_ALIAS="$2"     # github.com or github.com-corp
    local HOSTNAME="$3"       # always github.com
    local BASEFILE="$4"
    local KEYFILE="${BASEFILE}-${DEVICE_NAME}"

    echo ""
    echo "🔑 Ensuring $LABEL SSH key: $KEYFILE"

    if [[ -f "$KEYFILE" ]]; then
      echo "• Key exists — skipping generation."
    else
      echo "• Generating new SSH key for $LABEL..."
      ssh-keygen -t ed25519 -C "$LABEL@$(hostname)" -f "$KEYFILE" -N ""
    fi

    chmod 600 "$KEYFILE"
    chmod 644 "${KEYFILE}.pub"

    echo "• Adding $LABEL key to ssh-agent..."
    eval "$(ssh-agent -s)" >/dev/null
    ssh-add "$KEYFILE" || true

    echo "• Ensuring SSH config entry for $LABEL..."
    local START_MARK="# >>> bootstrap-ssh $LABEL >>>"
    local END_MARK="# <<< bootstrap-ssh $LABEL <<<"

    awk -v start="$START_MARK" -v end="$END_MARK" '
      BEGIN {skip=0}
      $0 == start {skip=1; next}
      $0 == end {skip=0; next}
      skip == 0 {print}
    ' "$SSH_CONFIG" > "${SSH_CONFIG}.tmp" && mv "${SSH_CONFIG}.tmp" "$SSH_CONFIG"

    {
      echo "$START_MARK"
      echo "Host $HOST_ALIAS"
      echo "  HostName $HOSTNAME"
      echo "  User git"
      echo "  AddKeysToAgent yes"
      echo "  UseKeychain yes"
      echo "  IdentityFile $KEYFILE"
      echo "$END_MARK"
      echo
    } >> "$SSH_CONFIG"
    chmod 600 "$SSH_CONFIG"

    echo "• Uploading $LABEL key to GitHub..."

    if [[ "$LABEL" == "personal" ]]; then
      ensure_gh_scope "github.com"
      gh ssh-key add "${KEYFILE}.pub" \
        --title "personal-${DEVICE_NAME}-bootstrap-$(date +%Y%m%d-%H%M%S)" \
        || echo "⚠️ Could not upload personal key — even after scope refresh."

    else
      # Ensure auth for corporate host
      if ! gh auth status --hostname github.com-corp >/dev/null 2>&1; then
        echo "🔐 Authenticating GitHub CLI for corporate identity..."
        gh auth login --hostname github.com-corp
      fi

      ensure_gh_scope "github.com-corp"
      gh ssh-key add "${KEYFILE}.pub" \
        --title "corp-${DEVICE_NAME}-bootstrap-$(date +%Y%m%d-%H%M%S)" \
        --hostname github.com-corp \
        || echo "⚠️ Could not upload corp key — even after scope refresh."
    fi

    echo "✔ $LABEL identity setup complete."
  }

  # PERSONAL ALWAYS RUNS (default)
  if [[ "$mode" == "personal" || "$mode" == "all" ]]; then
    ensure_key "personal" "github.com" "github.com" "$SSH_DIR/id_ed25519_personal"
  fi

  # CORPORATE (OPTIONAL)
  if [[ "$mode" == "corp" || "$mode" == "all" ]]; then
    ensure_key "corp" "github.com-corp" "github.com" "$SSH_DIR/id_ed25519_corp"
  fi

  echo ""
  echo "✅ SSH identity setup finished."
}

# =============================================================================
# Argument parsing
# =============================================================================
PROFILE="full"
DEVICE_NAME=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --full) PROFILE="full"; shift;;
    --minimal) PROFILE="minimal"; shift;;
    --apps-only) PROFILE="apps-only"; shift;;
    --corp) PROFILE="corp"; shift;;
    --all) PROFILE="all"; shift;;
    --device) DEVICE_NAME="$2"; shift 2;;
    *) shift;;
  esac
done

[[ -z "$DEVICE_NAME" ]] && DEVICE_NAME="$(hostname | tr ' ' '-' | tr '[:upper:]' '[:lower:]')"

log "Device: $DEVICE_NAME"
log "Profile: $PROFILE"

# =============================================================================
# Execute bootstrap steps
# =============================================================================
case "$PROFILE" in
  full)
    install_tools
    install_langs
    install_apps
    setup_shell
    setup_dotfiles
    setup_git
    setup_vscode
    setup_python
    setup_node
    ;;
  minimal)
    install_tools
    install_langs
    setup_shell
    setup_dotfiles
    setup_git
    setup_vscode
    setup_python
    setup_node
    ;;
  apps-only)
    install_apps
    ;;
esac

case "$PROFILE" in
  corp) setup_ssh corp "$DEVICE_NAME" ;;
  all)  setup_ssh all "$DEVICE_NAME" ;;
  *)    setup_ssh personal "$DEVICE_NAME" ;;
esac

log "Bootstrap complete!"
