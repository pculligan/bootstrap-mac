# 🚀 Mac Bootstrap  
A fully automated, JSON‑driven macOS bootstrap pipeline.

This repository provides a **safe**, **public**, **repeatable**, and **idempotent** bootstrap system that configures a completely fresh Mac into a fully working development environment with one command:

```
curl -fsSL https://raw.githubusercontent.com/pculligan/bootstrap-mac/main/bootstrap-stage-0.sh | sh
```

This single command:

1. **Installs or updates Homebrew**
2. **Installs or updates Homebrew Bash 5.x** (required for modern scripting)
3. **Downloads the unified bootstrap + JSON config**
4. **Executes the full bootstrap under Bash 5.x**
5. **Installs all CLI tools & apps from JSON**
6. **Installs Python & Node runtimes via pyenv & nvm**
7. **Installs global Python and Node packages**
8. **Configures shell environment (zsh + brew shellenv)**
9. **Installs Git configuration and global ignores**
10. **Fetches dotfiles directly from this repo**
11. **Installs VS Code extensions**
12. **Creates SSH keys (personal and/or corporate)**
13. **Uploads keys to GitHub with correct scopes**
14. **Runs idempotently — safe to re-run anytime**


# 📁 Repository Structure

This repo intentionally contains **everything required** for the full bootstrap:

| File | Purpose |
|------|---------|
| `bootstrap-stage-0.sh` | Minimal installer. POSIX-safe. Works on any Mac, even before Homebrew exists. |
| `bootstrap-stage-1.sh` | Full unified bootstrap. Requires Bash 5.x. Fully self‑contained. |
| `bootstrap-config.json` | Declarative configuration of tools, apps, runtimes, themes, global packages, VSCode extensions, etc. |
| `dotfiles/` | Dotfiles fetched during the bootstrap (`.zshrc`, `.gitconfig`, `.gitignore_global`). |

No private repositories are required.


# 🧩 How the Bootstrap Works

## Stage 0 — POSIX Installer  
Executed via `sh`, this script:

- Ensures Homebrew exists  
- Installs/updates Homebrew Bash  
- Installs jq (JSON parser)  
- Downloads stage‑1 and bootstrap‑config.json into `/tmp`  
- Executes stage‑1 under Homebrew Bash 5.x  

Stage‑0 has **zero dependencies** and works on any new macOS installation.


## Stage 1 — Unified Bootstrap  
Executed under Bash 5.x, this script:

- Verifies shell and environment
- Auto‑installs Rosetta on Apple Silicon (if missing)
- Parses all install lists from `bootstrap-config.json`
- Runs every installer function idempotently
- Fetches dotfiles from this repo
- Manages SSH identities (personal + corp)
- Uploads keys to GitHub automatically with required scopes
- Provides a `--verify` mode for diagnostics

Stage‑1 is fully self‑contained and does not require git or private repos.


# 📦 What Gets Installed (With Links)

Below is the complete list of everything installed, grouped by category, driven entirely by `bootstrap-config.json`.


## 🧰 CLI Tools  
(Defined in `tools` array)

| Tool | Description | Link |
|------|-------------|------|
| `jq` | JSON query processor | https://stedolan.github.io/jq/ |
| `yq` | YAML processor | https://github.com/mikefarah/yq |
| `fzf` | Fuzzy finder | https://github.com/junegunn/fzf |
| `ripgrep` | Fast search | https://github.com/BurntSushi/ripgrep |
| `fd` | Modern `find` alternative | https://github.com/sharkdp/fd |
| `tree` | Directory tree viewer | https://linux.die.net/man/1/tree |
| `htop` | System monitor | https://htop.dev |
| `wget` | Network downloader | https://www.gnu.org/software/wget/ |
| `curl` | HTTP client (Homebrew version) | https://curl.se |
| `bat` | `cat` with syntax highlighting | https://github.com/sharkdp/bat |
| `tldr` | Simplified man pages | https://tldr.sh |
| `zoxide` | Smarter `cd` | https://github.com/ajeetdsouza/zoxide |


## 🖥 Applications  
(Defined in `apps` array — installed via Homebrew Cask)

| App | Purpose | Link |
|------|---------|------|
| iTerm2 | Terminal emulator | https://iterm2.com |
| Visual Studio Code | Editor | https://code.visualstudio.com |
| Google Chrome | Browser | https://www.google.com/chrome |
| Slack | Communication | https://slack.com |
| Raycast | Launcher / productivity | https://www.raycast.com |


## 🐍 Python Runtime + Packages  
Driven by:

- `"python_version": "3.14"`
- `"python": [...]`

Installed via **pyenv**:

### Runtime:
- Python **3.14.x**

### Global Packages:
| Package | Purpose |
|---------|---------|
| `requests` | HTTP client |


## 🟩 Node.js Runtime + Packages  
Driven by:

- `"node_version": "lts"`
- `"node": [...]`

Installed via **nvm**:

### Runtime:
- Latest Node LTS

### Global Packages:
| Package | Purpose |
|---------|---------|
| `typescript` | TS compiler |


## 🧬 Runtime Managers  
(from `runtime_managers`)

- `pyenv` → Python versions  
- `nvm` → Node versions  
- `go` → Go language runtime  
- `rust` → Rust toolchain (via Homebrew)  


## ☁️ Infrastructure / DevOps  
(from `infra_devops`)

| Tool | Purpose | Link |
|------|---------|------|
| `awscli` | AWS CLI | https://aws.amazon.com/cli/ |
| `terraform` | IaC tooling | https://www.terraform.io |
| `kubectl` | Kubernetes CLI | https://kubernetes.io |
| `helm` | Kubernetes package manager | https://helm.sh |
| `k9s` | Kubernetes terminal UI | https://k9scli.io |


## 📄 Documentation Tools  
(from `documentation_tools`)

| Tool | Purpose | Link |
|------|---------|------|
| `pandoc` | Document converter | https://pandoc.org |


## 🎨 Terminal Theme  
(from `terminal_theme`)

- `powerlevel10k` → Recommended zsh theme  
  https://github.com/romkatv/powerlevel10k


# 🔐 SSH Identity Automation

The bootstrap fully manages:

### ✔ Personal GitHub identity  
- Generates key  
- Adds to ssh-agent  
- Writes config block  
- Uploads key to GitHub  
- Requests `admin:public_key` scope automatically  
- Skips upload if key already exists

### ✔ Corporate GitHub identity  
Same process, but under `github.com-corp` hostname.

### ✔ Idempotent  
SSH config blocks are replaced cleanly on each run.


# 🔧 Verification Mode

At any time, you can run:

```
bootstrap-stage-1.sh --verify
```

This prints a diagnostic summary:

- Bash version  
- Homebrew version  
- pyenv/nvm installed?  
- Node + Python runtime status  
- SSH key presence  
- Installed tools  
- VSCode extension count  

Useful for debugging and machine health checks.


# 🧹 Idempotency

The entire bootstrap system is:

- **Safe to run multiple times**
- **Non-destructive**
- **Self-healing**
- **Drift-correcting**

Re-running the bootstrap will:

- Upgrade tools  
- Reapply configs  
- Refresh SSH scopes  
- Skip re-uploading keys  
- Skip redundant installs  
- Preserve backups of dotfiles  

