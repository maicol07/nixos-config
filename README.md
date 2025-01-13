# Personal config for NixOS-WSL

## What Is Included

This config is a take on a productive terminal-driven
development environment based on my own preferences. However, it is trivial to
customize to your liking both by removing and adding tools that you prefer.

- The default editor is [Micro](https://micro-editor.github.io/)
- The default shell is `fish`
- Docker desktop on Windows integration is enabled by default
- The prompt is [Starship](https://starship.rs/)
- [`fzf`](https://github.com/junegunn/fzf),
  [`lsd`](https://github.com/lsd-rs/lsd),
  [`zoxide`](https://github.com/ajeetdsouza/zoxide), and
  [`broot`](https://github.com/Canop/broot) are integrated into `fish` by
  default
  - These can all be disabled easily by setting `enable = false` in
    [home.nix](home.nix), or just removing the lines all together
- [`direnv`](https://github.com/direnv/direnv) is integrated into `fish` by
  default
- `git` config is generated in [home.nix](home.nix) with options provided to
  enable private HTTPS clones with secret tokens
- `fish` config is generated in [home.nix](home.nix) and includes a bunch of plugins

## How to install
> From the great book [NixOS and Flakes](https://nixos-and-flakes.thiscute.world/nixos-with-flakes/other-useful-tips)
```bash
git clone git@github.com:maicol07/nixos-wsl-config.git .config/nixos
sudo mv /etc/nixos /etc/nixos.bak  # Backup the original configuration
sudo ln -s ~/.config/nixos /etc/nixos

# Deploy the flake.nix located at the default location (/etc/nixos)
sudo nixos-rebuild switch
```

## Project Layout

In order to keep the template as approachable as possible for new NixOS users,
this project uses a flat layout without any nesting or modularization.

- `flake.nix` is where dependencies are specified
  - `nixpkgs` is the current release of NixOS
  - `nixpkgs-unstable` is the current trunk branch of NixOS (ie. all the
    latest packages)
  - `home-manager` is used to manage everything related to your home
    directory (dotfiles etc.)
  - `nur` is the community-maintained [Nix User
    Repositories](https://nur.nix-community.org/) for packages that may not
    be available in the NixOS repository
  - `nixos-wsl` exposes important WSL-specific configuration options
  - `nix-index-database` tells you how to install a package when you run a
    command which requires a binary not in the `$PATH`
- `wsl.nix` is where the VM is configured
  - The hostname is set here
  - The default shell is set here
  - User groups are set here
  - WSL configuration options are set here
  - NixOS options are set here
- `home.nix` is where home configurations are set
- `home/programs` is the directory that contains all the programs that are installed
  on the system and their configurations
  - `home/programs/default.nix` is the entry point for all the programs
  - `home/programs/programs.nix` is where all the programs are defined
  - `home/programs/git.nix` is where the `git` configuration is set
  - `home/programs/micro.nix` is where the `micro` configuration is set
- `home/shell` is the directory that contains all the shell configurations
  - `home/shell/default.nix` is the entry point for all the shell configurations
  - `home/shell/fish.nix` is where the `fish` configuration is set
  - `home/starship.toml` is where the `starship` configuration is set
  - `home/starship-minimal.toml` is a streamlined version of the `starship`
    configuration that is used from the `fish-async-prompt` plugin
