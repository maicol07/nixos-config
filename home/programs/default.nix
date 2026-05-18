{ hostname, username, ... }: {
  imports =
    [
      ./packages.nix
      ./syncthing.nix
      ./git.nix
      ./micro.nix
    ]
    ++ (if hostname != "maicol07-server" then [ ./node-wrappers.nix ] else []);
  programs = {
    bat.enable = true;
    bottom.enable = true;
    btop.enable = true;
    fastfetch.enable = true;
    fd.enable = true;
    gh.enable = true;
    lazygit.enable = true;
    less.enable = true;
    nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep-since 4d --keep 3";
      flake = "/home/" + username + "/.config/nixos"; # sets NH_OS_FLAKE variable for you
    };
    vivid = {
      enable = true;
      enableFishIntegration = true;
      activeTheme = "modus-operandi";
    };
  };
}