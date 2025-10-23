{ ... }: {
  imports = [
    ./packages.nix
    ./git.nix
    ./micro.nix
  ];
  programs = {
    bat.enable = true;
    bottom.enable = true;
    btop.enable = true;
    fastfetch.enable = true;
    fd.enable = true;
    gh.enable = true;
    lazygit.enable = true;
    less.enable = true;
    vivid = {
      enable = true;
      enableFishIntegration = true;
      activeTheme = "modus-operandi";
    };
  };
}