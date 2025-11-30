#!/usr/bin/env bash
set -e

echo "🔧 Checking Homebrew…"
if command -v brew >/dev/null 2>&1; then
  echo "🔧 Homebrew already installed — updating…"
  brew update && brew upgrade
else
  echo "🔧 Installing Homebrew…"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
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

echo "🔐 GitHub authentication…"
gh auth login
GH_USER="$(gh api user --jq .login)"

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
./bootstrap.sh --full
