{ config, pkgs, ... }: {
  # Enable the Nix daemon (mandatory on multi-user/macOS installations)
  services.nix-daemon.enable = true;

  # Enable basic Zsh to allow the OS to hook Nix PATH variables
  programs.zsh.enable = true;

  # If you want to manage non-Nix packages via Homebrew in the future
  # homebrew.enable = true;
}
