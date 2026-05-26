<p align="center">
  <h1>❄️ NixOS & macOS Configuration</h1>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/NixOS-unstable-5277C3?logo=nixos&logoColor=white" alt="NixOS unstable">
  <img src="https://img.shields.io/badge/macOS-nix--darwin-999999?logo=apple&logoColor=white" alt="macOS nix-darwin">
  <img src="https://img.shields.io/badge/Home%20Manager-master-2848A9?logo=nixos&logoColor=white" alt="Home Manager">
  <img src="https://img.shields.io/badge/WSL-supported-0078D6?logo=windows&logoColor=white" alt="WSL">
</p>

<p align="center">
  Declarative, multi-host Nix configuration for WSL, bare-metal servers, and macOS — built with flakes and Home Manager.
</p>

---

## 🚀 Quick Start

```bash
git clone https://github.com/maicol07/nixos-config.git $HOME/.config/nixos
sudo mv /etc/nixos /etc/nixos.bak

# Deploy
sudo nixos-rebuild switch --flake $HOME/.config/nixos#maicol07-pc      # WSL (Galaxy)
sudo nixos-rebuild switch --flake $HOME/.config/nixos#maicol07-server  # Server
darwin-rebuild switch --flake $HOME/.config/nixos#MAICOL-MAC           # macOS
```

---

## 🖥️ Hosts

| Host | System | Type | Notes |
|---|---|---|---|
| `maicol07-pc` | `x86_64-linux` | WSL | Galaxy Book |
| `maicol07-galaxy` | `x86_64-linux` | WSL | Ultrabook |
| `maicol07-server` | `x86_64-linux` | Bare-metal | Secure Boot via Lanzaboote |
| `MAICOL-MAC` | `aarch64-darwin` | nix-darwin | Apple Silicon |

---

## ✨ Features

- **Shell** — Fish with Starship prompt (full + minimal), `fzf`, `lsd`, `zoxide`, `broot`, `direnv`
- **Editor** — [Micro](https://micro-editor.github.io/) pre-configured
- **Git toolchain** — lazygit, git-crypt, interactive rebase, GitHub Copilot CLI
- **Docker** — enabled everywhere; WSL connects to Docker Desktop on Windows
- **Nix tooling** — `nh` system manager, `nixd` LSP, `alejandra`/`deadnix`/`statix` formatters
- **Dev stack** — Node.js (latest), Python 3, PHP 8.5, Deno, MariaDB client
- **Cloud/Infra** — AWS CLI, Terraform, kubectl, k9s, Supabase CLI
- **Modular** — every tool is a separate module; toggle or remove as you like

---

## 📦 Installation

<details>
<summary><b>NixOS (WSL)</b></summary>

```bash
git clone https://github.com/maicol07/nixos-config.git $HOME/.config/nixos
sudo mv /etc/nixos /etc/nixos.bak
sudo nixos-rebuild switch --flake $HOME/.config/nixos#maicol07-pc     # Galaxy
sudo nixos-rebuild switch --flake $HOME/.config/nixos#maicol07-galaxy # Ultrabook
```
</details>

<details>
<summary><b>NixOS (Bare-metal Server)</b></summary>

```bash
git clone https://github.com/maicol07/nixos-config.git $HOME/.config/nixos
sudo cp /etc/nixos/hardware-configuration.nix \
  $HOME/.config/nixos/hardware/maicol07-server/hardware-configuration.nix

sudo nixos-rebuild boot --flake $HOME/.config/nixos#maicol07-server   # Secure Boot
sudo nixos-rebuild switch --flake $HOME/.config/nixos#maicol07-server
```
</details>

<details>
<summary><b>macOS (nix-darwin)</b></summary>

Install [Lix](https://lix.systems/install/) first.

```bash
git clone https://github.com/maicol07/nixos-config.git $HOME/.config/nixos
cd $HOME/.config/nixos
nix run nix-darwin -- switch --flake $HOME/.config/nixos#MAICOL-MAC   # First run
```

Then use the shorter command:

```bash
darwin-rebuild switch --flake $HOME/.config/nixos#MAICOL-MAC
```
</details>

---

## 🗂️ Layout

```
.
├── flake.nix                     # Entry point: inputs, outputs, host definitions
├── common.nix                    # Shared across all hosts
├── nixos.nix                     # NixOS system config
├── darwin.nix                    # macOS system config
├── wsl.nix                       # WSL-only settings
├── server.nix                    # Bare-metal server config
│
├── hardware/
│   └── maicol07-server/          # Per-machine hardware-configuration.nix
│
├── home/
│   ├── default.nix               # Home Manager entry point
│   ├── programs/
│   │   ├── default.nix           # CLI tools: bat, gh, lazygit, nh, etc.
│   │   ├── git.nix               # Git configuration
│   │   ├── micro.nix             # Micro editor config
│   │   ├── syncthing.nix         # File sync
│   │   ├── node-wrappers.nix     # Node.js shell wrappers
│   │   ├── packages.nix          # Package orchestration
│   │   └── packages/
│   │       ├── common.nix        # Every host
│   │       ├── personal.nix      # PCs + Mac
│   │       ├── server.nix        # Server only
│   │       └── linux.nix         # Linux-only (nemo, etc.)
│   └── shell/
│       ├── fish.nix
│       ├── config.fish
│       ├── starship.toml
│       └── starship-minimal.toml
│
└── .github/workflows/
    └── build.yml                 # CI
```

### Package Selection

`home/programs/packages.nix` composes packages by hostname:

| Host | `common` | `server` | `personal` | `linux` |
|---|:---:|:---:|:---:|:---:|
| `maicol07-server` | ✓ | ✓ | | |
| `maicol07-pc` | ✓ | | ✓ | ✓ |
| `maicol07-galaxy` | ✓ | | ✓ | ✓ |
| `MAICOL-MAC` | ✓ | | ✓ | |

---

## 🧩 Flake Inputs

| Input | Branch | Purpose |
|---|---|---|
| `nixpkgs` | `nixos-unstable` | Package repository |
| `home-manager` | `master` | Dotfiles & user packages |
| `nix-darwin` | — | macOS declarative management |
| `nixos-wsl` | — | WSL integration modules |
| `nur` | — | Community Nix User Repositories |
| `nix-index-database` | — | `command-not-found` database |
| `lanzaboote` | `v0.4.3` | Secure Boot signing |
| `lfk` | — | Custom input |

---

## 🔧 Maintenance

**Update all inputs**  
```bash
nix flake update
```

**Compare package versions between generations**  
```bash
nix profile diff-closures --profile /nix/var/nix/profiles/system
nix store diff-closures /nix/var/nix/profiles/system-99-link /run/current-system
nix profile history --profile /nix/var/nix/profiles/system
```

**Garbage-collect old deployments**  
```bash
gc
```
