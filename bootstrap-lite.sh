#!/usr/bin/env bash
set -e

echo "🔧 Installing Homebrew…"
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

echo "🔧 Installing core tools…"
/opt/homebrew/bin/brew install git gh

echo "🔐 GitHub authentication…"
gh auth login

echo "⬇️  Cloning private bootstrap repo…"
gh repo clone patrick/dev-bootstrap ~/dev-bootstrap

echo "🚀 Running full bootstrap…"
cd ~/dev-bootstrap
./bootstrap.sh --full
