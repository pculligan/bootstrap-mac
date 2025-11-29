# 🧰 mac-bootstrap
### First-stage bootstrap for setting up a brand-new macOS workstation

This repository contains a small, safe, public bootstrap script that prepares a completely fresh Mac for your full environment automation.

You use this when you sit down at a new or reset machine and want to get to your real setup scripts as fast as possible.

---

# 🚀 Quick Start

Open **Terminal** on a fresh Mac and run:

```
curl -fsSL https://raw.githubusercontent.com/pculligan/mac-bootstrap/main/bootstrap-lite.sh | bash
```

This single command:

1. Installs or updates Homebrew  
2. Installs or updates git and GitHub CLI (gh)  
3. Prompts you to authenticate with GitHub  
4. Detects your GitHub username  
5. Creates a `~/work` directory  
6. Clones your private `dev-bootstrap` repo into `~/work/dev-bootstrap`  
7. Runs your full workstation bootstrap  

After a few minutes, your machine will be configured exactly the way you like.

---

# 📦 What This Script Does (High-Level)

### 1. Homebrew Install/Upgrade
Ensures the package manager is present and current.

### 2. Core Tools
Ensures `git` and `gh` are installed and upgraded.

### 3. GitHub Authentication
Runs:

```
gh auth login
```

to connect the machine to your GitHub identity.

### 4. Repo Cloning
Automatically figures out your GitHub username:

```
GH_USER="$(gh api user --jq .login)"
```

Then clones:

```
gh repo clone "$GH_USER/dev-bootstrap" ~/work/dev-bootstrap
```

### 5. Full Bootstrap Launch
Hands off to your private automation:

```
./bootstrap.sh --full
```

---

# 🔒 Private Repo Requirements

Your private repo must be named:

```
dev-bootstrap
```

and must contain:

- `bootstrap.sh`
- `/scripts` folder
- `/config` folder
- dotfiles, package lists, app lists, etc.

This repository (`mac-bootstrap`) intentionally contains no sensitive information and is safe to be public.

---

# 🛠 Updating the Bootstrap Script

Because this script is tiny, you rarely need to update it.

Typical update reasons:

- Homebrew changes installation path  
- You rename your private repo  
- You want to support additional authentication methods  

---
