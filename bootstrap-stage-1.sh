#!/opt/homebrew/bin/bash

set -euo pipefail

# Verify we are running under Homebrew Bash (5.x), not system bash (3.2)
CURRENT_SHELL_BIN="$(ps -p $$ -o comm=)"
BASH_VERSION_STR="$("$CURRENT_SHELL_BIN" --version 2>/dev/null | head -n1 || echo 'unknown')"

echo "🐚 Running under shell: $CURRENT_SHELL_BIN"
echo "🔎 Detected Bash version: $BASH_VERSION_STR"

if [[ "$CURRENT_SHELL_BIN" != "/opt/homebrew/bin/bash" ]]; then
  echo "❌ ERROR: Stage 1 is NOT running under Homebrew Bash."
  echo "    Detected: $CURRENT_SHELL_BIN"
  echo "    Expected: /opt/homebrew/bin/bash"
  echo ""
  echo "💡 This indicates stage 0 did NOT relaunch correctly."
  echo "    Do NOT continue — bootstrap will behave unpredictably."
  exit 1
fi

# Optionally validate version begins with "GNU bash, version 5"
if ! echo "$BASH_VERSION_STR" | grep -q "version 5"; then
  echo "❌ ERROR: Bash version is not 5.x — current version:"
  echo "    $BASH_VERSION_STR"
  echo ""
  echo "💡 Stage 1 requires Homebrew Bash 5.x to run safely."
  exit 1
fi

echo "✔ Stage 1 running under correct Bash: $BASH_VERSION_STR"

# Auto-detect device name
DEVICE_NAME="$(scutil --get ComputerName 2>/dev/null | tr ' ' '-' | tr '[:upper:]' '[:lower:]')"
echo "💻 Device name detected: $DEVICE_NAME"

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

/opt/homebrew/bin/bash ./bootstrap.sh --full --device "$DEVICE_NAME"
