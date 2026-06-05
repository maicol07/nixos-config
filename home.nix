{
  pkgs,
  lib,
  username,
  nix-index-database,
  isDarwin ? false,
  ...
}: {
  imports = [
    nix-index-database.homeModules.nix-index
    ./home
  ];

  home.stateVersion = "24.11";

  home = {
    inherit username;
    homeDirectory = if isDarwin then "/Users/${username}" else "/home/${username}";

    sessionVariables = {
      EDITOR = "micro";
      PNPM_HOME = if isDarwin then "$HOME/Library/pnpm" else "$HOME/.local/share/pnpm";
    };
    # sessionVariables.SHELL = "/etc/profiles/per-user/${username}/bin/fish";

  };
  nix.settings.substituters = [
    "https://cache.nixos.org/"
    "https://nix-community.cachix.org"
  ];

  nix.settings.trusted-public-keys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
  ];

  programs = {
    home-manager.enable = true;
    nix-index.enable = true;
    nix-index.enableFishIntegration = true;
    nix-index-database.comma.enable = true;
  };
}
