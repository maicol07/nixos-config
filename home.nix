{
  pkgs,
  lib,
  username,
  nix-index-database,
  system,
  ...
}: {
  imports = [
    nix-index-database.hmModules.nix-index
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
        ${pkgs.corepack_latest}/bin/pnpm completion fish > /home/${username}/.local/share/fish/vendor_completions.d/pnpm.fish
      '';
    };
  };
  
  # Uncomment when https://github.com/NixOS/nixpkgs/pull/371832 is merged
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
