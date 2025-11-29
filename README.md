# Mac Bootstrap

This repository contains a small, safe, public bootstrap script that prepares a completely fresh Mac for my full environment automation.

```
curl -fsSL https://raw.githubusercontent.com/pculligan/mac-bootstrap/main/bootstrap-lite.sh | bash
```

This single command:

1. Installs or updates Homebrew  
2. Installs or updates git and GitHub CLI (gh)  
3. Prompts me to authenticate with GitHub  
4. Detects my GitHub username  
5. Creates a `~/work` directory  
6. Clones my private `dev-bootstrap` repo into `~/work/dev-bootstrap`  
7. Runs my full workstation bootstrap  

After a few minutes, my machine will be configured exactly the way I like.

## 🔒 Private Repo Requirements

The repo must be named:

```
dev-bootstrap
```

and must contain:

- `bootstrap.sh`
- `/scripts` folder
- `/config` folder
- dotfiles, package lists, app lists, etc.

This repository (`mac-bootstrap`) intentionally contains no sensitive information and is safe to be public.

## 🛠 Updating the Bootstrap Script

Because this script is tiny, I rarely need to update it.

Typical update reasons:

- Homebrew changes installation path  
- I rename my private repo  
- I want to support additional authentication methods

