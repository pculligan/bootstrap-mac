#!/opt/homebrew/bin/bash
set -euo pipefail

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

./bootstrap.sh --full --device "$DEVICE_NAME"
