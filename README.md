# Mac Bootstrap

This repository contains a small, safe, public bootstrap script that prepares a completely fresh Mac for my full environment automation.

```
curl -fsSL https://raw.githubusercontent.com/pculligan/bootstrap-mac/main/bootstrap-stage-0.sh | sh
```

This single command:

1. Installs or updates Homebrew  
2. Installs or updates Homebrew Bash  
3. Downloads the unified bootstrap script and configuration  
4. Runs the unified bootstrap under Homebrew Bash 5.x  
5. Installs all CLI tools, apps, language runtimes, Python & Node globals  
6. Configures my shell, Git, dotfiles, and VS Code extensions  
7. Creates SSH identities (personal and/or corporate)  
8. Finishes with a fully configured Mac exactly how I want it

## 📁 Repository Structure

This repository intentionally contains everything needed for a full bootstrap:

- `bootstrap-stage-0.sh` — POSIX‑safe installer (always works on a fresh Mac)
- `bootstrap-stage-1.sh` — unified bootstrap (requires Homebrew Bash 5.x)
- `bootstrap-config.json` — declarative list of all tools, apps, runtimes, globals, themes, and extensions

No private repositories are required.
