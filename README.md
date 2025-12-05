# Mac Bootstrap  
A fully automated, idempotent Apple Silicon macOS bootstrap pipeline for development machines.

This project configures a brand‑new Mac into a complete development environment using one command:

```
curl -fsSL https://raw.githubusercontent.com/pculligan/bootstrap-mac/main/bootstrap-install.sh | sh
```

This single command:

1. Installs or updates Homebrew  
2. Installs Homebrew Bash 5.x (required for the bootstrap engine)  
3. Installs jq  
4. Downloads the `bootstrap` CLI and layered JSON config  
5. Executes the bootstrap engine under Bash 5.x  
6. Applies the **layered configuration** (base + personal or corp)  
7. Installs CLI tools, GUI apps, runtimes, and global packages  
8. Applies shell config, dotfiles, Git, and VS Code extensions  
9. Sets up SSH (profile‑aware: personal or personal+corp)  
10. Uploads SSH keys to GitHub only when already authenticated  
11. Verifies machine state  
12. Runs safely and idempotently every time  

---

# Repository Structure

| File | Purpose |
|------|---------|
| `bootstrap-install.sh` | POSIX installer; installs Homebrew, Bash, jq, and the bootstrap CLI. |
| `bootstrap` | The full bootstrap engine (profiles, installers, SSH, verify, upgrade). |
| `bootstrap-config.json` | Declarative layered configuration (base, personal, corp). |
| `bootstrap-stage-1.sh` | Legacy compatibility script (deprecated). |
| `dotfiles/` | `.zshrc`, `.gitconfig`, `.gitignore_global`. |

Everything required for bootstrapping is within this repository.

---

# How the Bootstrap Works

## Stage 0 — POSIX Installer
Runs under `/bin/sh`, performs:

- Homebrew installation (if needed)  
- Bash 5.x installation  
- jq installation  
- Download of the `bootstrap` CLI and `bootstrap-config.json`  
- Invocation of the main bootstrap engine  

No dependencies required. Works on any fresh macOS install.

---

## Bootstrap CLI — The Modern Engine

This is the real bootstrap layer. It:

- Loads and merges layered configuration (`base`, `personal`, `corp`)  
- Installs CLI tools and GUI apps  
- Installs pyenv, nvm, go, and rust  
- Installs Python & Node versions from JSON  
- Installs global Python and Node packages  
- Applies shell configuration and dotfiles  
- Writes Git config and VS Code extensions  
- Sets up SSH identities (profile‑aware)  
- Uploads keys to GitHub only when authenticated  
- Provides `run`, `verify`, `upgrade`, `update`, and optional installs  
- Runs entirely locally (Stage‑1 no longer participates)

---

# Layered Configuration (base / personal / corp)

The JSON configuration defines layers:

```
{
  "base": { ... },
  "personal": { ... },
  "corp": { ... },
  "python_version": "3.14",
  "node_version": "lts"
}
```

### Base Layer  
Installed on **every** machine.  
Contains CLI tools, core apps, runtimes, global packages, VS Code extensions.

### Personal Layer  
Installed only when profile = `personal` (default).  
Typical user-level apps (e.g., ChatGPT, WhatsApp, Raycast).

### Corp Layer  
Installed only when profile = `corp`.  
Contains only corporate‑safe extras (e.g., RealVNC Viewer).  
Also triggers *corporate SSH* setup when GitHub Enterprise auth exists.

### Profile Selection

```
bootstrap run --profile personal   # default
bootstrap run --profile base
bootstrap run --profile corp
```

### Merging Rules

- Base layer always applied  
- Personal or corp layer overlays base  
- Installers and verification operate on merged arrays  
- SSH setup mode adapts to profile  

---

# What Gets Installed

All installations are driven by `bootstrap-config.json`.

---

## CLI Tools (Homebrew)

Installed from `base.tools[]`, including:

- jq, yq, fzf, ripgrep, fd, tree, htop  
- wget, curl, bat, tldr, zoxide  

---

## Applications (Homebrew Cask)

Installed from `base.apps[]`, `personal.apps[]`, or `corp.apps[]`.

Base includes:

- iTerm2  
- Visual Studio Code  
- Google Chrome  
- Slack  
- Raycast  

Personal includes:

- ChatGPT  
- WhatsApp  

Corp includes:

- RealVNC Viewer  

---

## Python Runtime + Global Packages

Installed via **pyenv** using:

```
"python_version": "3.14"
"python": ["requests", ...]
```

---

## Node.js Runtime + Global Packages

Installed via **nvm** using:

```
"node_version": "lts"
"node": ["typescript", ...]
```

---

## Runtime Managers

From `runtime_managers[]`:

- pyenv  
- nvm  
- go  
- rust  

---

## Infra / DevOps Tools

From `infra_devops[]`:

- awscli  
- terraform  
- kubectl  
- helm  
- k9s  

---

## Documentation Tools

From `documentation_tools[]`:

- pandoc  

---

## Terminal Theme

From `terminal_theme[]`:

- powerlevel10k  

---

# SSH Identity Automation (Profile‑Aware)

### Personal Mode (base/personal profiles)

- Generates personal SSH key  
- Writes SSH config block  
- Adds to ssh-agent  
- Uploads to GitHub only if authenticated  
- Never forces authentication  
- Never re-uploads  

### Corporate Mode (`--profile corp`)

- Generates personal + corp SSH keys  
- Writes distinct corp host block (`Host github.com-corp`)  
- Uploads corp key only if GitHub Enterprise auth already exists  
- Never forces a corporate login on personal machines  

### Idempotency  
Keys are never re-generated, config is regenerated cleanly, and GitHub uploads only occur once.

---

# Verification Mode

```
bootstrap verify
```

Verifies merged configuration:

- Bash version  
- Homebrew health  
- Required CLI tools (merged layers)  
- Required GUI apps  
- Python runtime + packages  
- Node runtime + packages  
- VS Code extensions  
- SSH keys appropriate to profile  

Exit codes:
- `0` = machine matches config  
- `1` = drift or missing items  

---

# Upgrade Mode

```
bootstrap upgrade
```

Upgrades all bootstrap-managed software:

- brew update  
- brew upgrade formulas  
- brew upgrade casks  
- runtime upgrades (pyenv, nvm, rust, go)  
- upgrades global Python/Node packages  

Does not modify:
- Dotfiles  
- Shell config  
- Keys  
- User preferences  

---

# Update (Self-Update)

```
bootstrap update
```

Downloads the latest version of the bootstrap CLI and atomically replaces itself.

---

# Examples

### Full bootstrap (personal mode)
```
bootstrap run
```

### Corporate developer machine
```
bootstrap run --profile corp
```

### Base only
```
bootstrap run --profile base
```

### Upgrade installed software
```
bootstrap upgrade
```

### Verify configuration
```
bootstrap verify
```

### Manually test SSH setup
```
bootstrap ssh local personal
bootstrap ssh local corp
```

---

# Idempotency Guarantees

Every run:

- Is safe and repeatable  
- Upgrades rather than overwrites  
- Reapplies configuration cleanly  
- Never regenerates keys  
- Never overwrites user dotfiles without backup  
- Corrects drift  
- Skips all redundant installs  

This system is safe to run as often as you want.

---

# Notes

- Script is ASCII-only to be fully strict-mode-safe  
- Stage‑1 is retained only for legacy reasons  
- Bootstrap CLI is the authoritative, modern engine  
- Config is layered for personal vs corporate environments  