{
  pkgs,
  lib,
  username,
  nix-index-database,
  ...
}: {
  imports = [
    nix-index-database.homeModules.nix-index
    ./home
  ];

  home.stateVersion = "24.11";

  home = {
    username = "${username}";
    homeDirectory = "/home/${username}";

    sessionVariables.EDITOR = "micro";
    # sessionVariables.SHELL = "/etc/profiles/per-user/${username}/bin/fish";

    activation = {
      installPnpmCompletions = lib.hm.dag.entryAfter ["writeBoundary"] ''
      mkdir -p /home/${username}/.local/share/fish/vendor_completions.d
      rm -f /home/${username}/.local/share/fish/vendor_completions.d/pnpm.fish
        ${pkgs.corepack}/bin/pnpm completion fish > /home/${username}/.local/share/fish/vendor_completions.d/pnpm.fish
      '';
    };
  };
  nix.settings.substituters = [
    "https://nix-community.cachix.org"
  ];

  nix.settings.trusted-public-keys = [
    "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
  ];
  
  # systemd.user.tmpfiles.rules = [
  #   "L+ %h/.local/share/fish/vendor_completions.d/pnpm.fish - - - - ${pkgs.runCommandNoCC "pnpm-completion" {} "${lib.getExe pkgs.pnpm} completion fish >$out"}"
  # ];

  programs = {
    home-manager.enable = true;
    nix-index.enable = true;
    nix-index.enableFishIntegration = true;
    nix-index-database.comma.enable = true;
  };
}
