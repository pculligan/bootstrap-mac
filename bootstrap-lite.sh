#!/usr/bin/env bash
set -e

echo "📦 Stage 0: Minimal bootstrap (brew + bash)…"

# Detect architecture
ARCH="$(uname -m)"
echo "🔍 Architecture: $ARCH"

# Install Homebrew if missing
if ! command -v brew >/dev/null 2>&1; then
  echo "🍺 Installing Homebrew…"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  echo "🍺 Homebrew already installed — updating…"
  brew update && brew upgrade
fi

# Ensure Homebrew bash is installed
if ! brew list bash >/dev/null 2>&1; then
  echo "🔧 Installing Homebrew bash…"
  brew install bash
else
  echo "🔧 Homebrew bash already installed."
fi

# Ensure PATH includes Homebrew bash
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
hash -r

# Relaunch bootstrap-lite2 under Homebrew bash
if [[ -x /opt/homebrew/bin/bash ]]; then
  echo "🔄 Launching bootstrap-lite2.sh under Homebrew bash…"
  # Fetch latest bootstrap-lite2.sh from GitHub
  echo "⬇️  Downloading latest bootstrap-lite2.sh…"
  curl -fsSL https://raw.githubusercontent.com/pculligan/mac-bootstrap/main/bootstrap-lite2.sh \
    -o /Users/patrickculligan/work/bootstrap-mac/bootstrap-lite2.sh

  chmod +x /Users/patrickculligan/work/bootstrap-mac/bootstrap-lite2.sh
  echo "✔ bootstrap-lite2.sh updated."

  exec /opt/homebrew/bin/bash /Users/patrickculligan/work/bootstrap-mac/bootstrap-lite2.sh "$@"
else
  echo "❌ Homebrew bash not found after install. Cannot continue."
  exit 1
fi
