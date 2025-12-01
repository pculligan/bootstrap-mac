#!/bin/sh
set -e

echo "📦 Stage 0: Minimal bootstrap (brew + bash)…"

# Detect architecture
ARCH="$(uname -m)"
echo "🔍 Architecture: $ARCH"

# Install Homebrew if missing
if ! command -v brew >/dev/null 2>&1; then
  echo "🍺 Installing Homebrew…"
  /bin/sh -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
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
PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
export PATH
hash -r 2>/dev/null || true

# Download bootstrap-stage-1 into /tmp
echo "⬇️  Downloading bootstrap-stage-1.sh into /tmp…"
TMP_DL="$(mktemp /tmp/bootstrap-stage-1.XXXXXX)"

curl -fsSL https://raw.githubusercontent.com/pculligan/mac-bootstrap/main/bootstrap-stage-1.sh -o "$TMP_DL"

chmod +x "$TMP_DL"
echo "✔ bootstrap-stage-1.sh downloaded to $TMP_DL"

# Execute stage 1 under Homebrew bash
exec /opt/homebrew/bin/bash "$TMP_DL" "$@"
