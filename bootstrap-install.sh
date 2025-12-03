#!/bin/sh
set -e

# bootstrap-install.sh
# Stage-0 style installer: ensure Homebrew + Bash + jq,
# then install the local `bootstrap` CLI and config, and invoke it.

REPO_BASE="https://raw.githubusercontent.com/pculligan/bootstrap-mac/main"

echo "📦 bootstrap-mac installer (bootstrap-install.sh)"

ensure_curl() {
  if ! command -v curl >/dev/null 2>&1; then
    echo "❌ curl is required but not installed."
    echo "   Please install curl and re-run this installer."
    exit 1
  fi
}

ensure_brew() {
  if command -v brew >/dev/null 2>&1; then
    echo "🍺 Homebrew already installed — updating..."
    brew update >/dev/null 2>&1 || true
    return
  fi

  echo "🍺 Installing Homebrew…"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

ensure_path_with_brew() {
  # Apple Silicon only: Homebrew is expected at /opt/homebrew
  if [ -d "/opt/homebrew/bin" ]; then
    PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
    export PATH
  else
    echo "❌ Expected Homebrew at /opt/homebrew/bin (Apple Silicon only)."
    echo "   Please ensure Homebrew is installed correctly and re-run this installer."
    exit 1
  fi
}

install_prereqs() {
  echo "🔧 Ensuring Bash 5 and jq are installed via Homebrew…"
  brew list bash >/dev/null 2>&1 || brew install bash
  brew list jq >/dev/null 2>&1 || brew install jq
}

install_bootstrap_cli() {
  # Apple Silicon only: install bootstrap CLI into /opt/homebrew/bin
  HELPER_TARGET="/opt/homebrew/bin/bootstrap"

  echo "📥 Installing 'bootstrap' CLI to $HELPER_TARGET…"
  TMP_CLI="${HELPER_TARGET}.tmp"

  curl -fsSL "${REPO_BASE}/bootstrap" -o "$TMP_CLI"
  chmod +x "$TMP_CLI"
  # Use mv to atomically replace if it already exists
  mv "$TMP_CLI" "$HELPER_TARGET"

  echo "✔ 'bootstrap' CLI installed at $HELPER_TARGET"
}

install_config() {
  CONFIG_DIR="$HOME/.config/bootstrap-mac"
  CONFIG_PATH="$CONFIG_DIR/bootstrap-config.json"

  echo "📥 Installing bootstrap config to $CONFIG_PATH…"
  mkdir -p "$CONFIG_DIR"
  curl -fsSL "${REPO_BASE}/bootstrap-config.json" -o "$CONFIG_PATH"
  echo "✔ Config installed at $CONFIG_PATH"
}

run_bootstrap() {
  echo "🚀 Invoking 'bootstrap run' under Homebrew Bash (Apple Silicon)…"

  # Apple Silicon only: require Homebrew Bash at /opt/homebrew/bin/bash
  HBASH="/opt/homebrew/bin/bash"
  if [ ! -x "$HBASH" ]; then
    echo "❌ Homebrew Bash not found at $HBASH."
    echo "   bootstrap requires a modern Bash installed via Homebrew (Apple Silicon)."
    echo "   Please ensure 'brew install bash' succeeded and re-run this installer."
    exit 1
  fi

  BOOTSTRAP_PATH="$(command -v bootstrap 2>/dev/null || echo "bootstrap")"

  "$HBASH" "$BOOTSTRAP_PATH" run
}

echo "🔍 Checking prerequisites..."
ensure_curl
ensure_brew
ensure_path_with_brew
install_prereqs
install_bootstrap_cli
install_config
run_bootstrap

echo "✅ bootstrap-mac installation flow complete."
