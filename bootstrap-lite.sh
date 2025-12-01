#!/usr/bin/env bash
# Relaunch bootstrap-lite under Homebrew Bash if not already running under it
if [[ "$(ps -p $$ -o comm=)" != "/opt/homebrew/bin/bash" ]]; then
  if [[ -x /opt/homebrew/bin/bash ]]; then
    echo "🔄 Relaunching bootstrap-lite.sh under Homebrew bash…"
    exec /opt/homebrew/bin/bash --noprofile --norc "$0" "$@"
  fi
fi
# Detect if macOS Terminal is forcing /bin/bash as the startup shell
if [[ "$TERM_PROGRAM" == "Apple_Terminal" ]]; then
  TERMINAL_SHELL_CMD="$(defaults read com.apple.Terminal 'Shell' 2>/dev/null || echo '')"
  if echo "$TERMINAL_SHELL_CMD" | grep -q '/bin/bash'; then
    echo "🚨 Terminal.app is configured to force /bin/bash as the startup shell."
    echo "   This overrides your login shell and BREAKS bootstrap."
    echo "   Please change this setting:"
    echo "      Terminal → Settings → Profiles → Shell → Shells open with → Default login shell"
    echo "   After changing it, restart Terminal."
  fi
fi
set -e

# Ensure Homebrew bin directories are preferred in PATH (must happen before any bash calls)
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
echo "🔧 Updated PATH early to prefer Homebrew binaries."

# Guard: ensure "bash" resolves to Homebrew bash
if [[ "$(command -v bash)" != "/opt/homebrew/bin/bash" ]]; then
  export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
  hash -r
fi

# Auto-detect device name
DEVICE_NAME="$(scutil --get ComputerName 2>/dev/null | tr ' ' '-' | tr '[:upper:]' '[:lower:]')"
echo "💻 Device name detected: $DEVICE_NAME"

echo "🔧 Checking Homebrew…"
if command -v brew >/dev/null 2>&1; then
  echo "🔧 Homebrew already installed — updating…"
  brew update && brew upgrade
else
  echo "🔧 Installing Homebrew…"
  /opt/homebrew/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

echo "🔧 Ensuring git and gh are installed/up-to-date…"

ensure_brew_pkg() {
  if brew list "$1" >/dev/null 2>&1; then
    echo "🔧 Updating $1…"
    brew upgrade "$1"
  else
    echo "🔧 Installing $1…"
    brew install "$1"
  fi
}

ensure_brew_pkg git
ensure_brew_pkg gh
ensure_brew_pkg bash

# Ensure Homebrew bin directories are preferred in PATH
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
echo "🔧 Updated PATH to prefer Homebrew binaries."

# Ensure Homebrew bash is a valid login shell
if ! grep -qx "/opt/homebrew/bin/bash" /etc/shells; then
  echo "🔧 Adding Homebrew bash to /etc/shells… (requires sudo)"
  echo "/opt/homebrew/bin/bash" | sudo tee -a /etc/shells >/dev/null
fi

# Detect current login shell
CURRENT_SHELL="$(dscl . -read /Users/$USER UserShell | awk '{print $2}')"
echo "🔍 Current login shell: $CURRENT_SHELL"

# Switch login shell to Homebrew bash if needed
if [[ "$CURRENT_SHELL" != "/opt/homebrew/bin/bash" ]]; then
  echo "💡 Switching login shell to Homebrew bash… (requires sudo)"
  sudo chsh -s /opt/homebrew/bin/bash "$USER"
  echo "✔ Login shell updated. You MUST close ALL terminal windows after bootstrap completes."
else
  echo "✔ Login shell already set to Homebrew bash."
fi

# Confirm active bash version
echo "🔧 Active bash version: $(/opt/homebrew/bin/bash --version | head -n 1)"

echo "🔐 Checking GitHub authentication…"

if gh auth status >/dev/null 2>&1; then
  echo "✔ Already authenticated with GitHub."
else
  echo "🔐 GitHub authentication required…"
  gh auth login
fi

GH_USER="$(gh api user --jq .login)"
echo "✔ Logged in as $GH_USER"

if [[ -d ~/work/bootstrap-dev/.git ]]; then
  echo "📁 Existing bootstrap-dev repo detected — pulling latest changes…"
  cd ~/work/bootstrap-dev
  git pull --rebase || true
else
  echo "⬇️  Cloning private bootstrap repo…"
  gh repo clone "$GH_USER/bootstrap-dev" ~/work/bootstrap-dev
fi

echo "🚀 Running full bootstrap…"
cd ~/work/bootstrap-dev

# Ensure bootstrap.sh is executable
if [[ ! -x ./bootstrap.sh ]]; then
  echo "🔧 Fixing permissions on bootstrap.sh…"
  chmod +x ./bootstrap.sh || true
fi

# Ensure all scripts in scripts/ are executable
if [[ -d ./scripts ]]; then
  echo "🔧 Fixing permissions for all .sh files in scripts/…"
  chmod +x ./scripts/*.sh 2>/dev/null || true
fi

./bootstrap.sh --full --device "$DEVICE_NAME"
