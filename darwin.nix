{ config, pkgs, username, ... }: {
  # Define the user's home directory on macOS
  users.users.${username} = {
    home = pkgs.lib.mkForce "/Users/${username}";
  };

  # Force Home Manager to use the macOS path, overriding the Linux one in home.nix
  home-manager.users.${username} = {
    home.homeDirectory = pkgs.lib.mkForce "/Users/${username}";
  };

  # Enable the Nix daemon (mandatory on multi-user/macOS installations)
  services.nix-daemon.enable = true;

  # Enable basic Zsh to allow the OS to hook Nix PATH variables
  programs.zsh.enable = true;

  # If you want to manage non-Nix packages via Homebrew in the future
  # homebrew.enable = true;

  # This value determines the Nix-Darwin release from which defaults are taken
  system.stateVersion = 5;
}
