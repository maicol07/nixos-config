{
  username,
  hostname,
  pkgs,
  inputs,
  lib,
  ...
}: {
  time.timeZone = "Europe/Rome";

  networking.hostName = "${hostname}";

  programs.fish.enable = true;
  environment.pathsToLink = ["/share/fish"];
  environment.shells = [pkgs.fish];

  environment.enableAllTerminfo = true;

  security.sudo.wheelNeedsPassword = false;

  users.users.${username} = {
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups = [
      "wheel"
      "docker"
    ];
  };

  home-manager.users.${username} = {
    imports = [
      ./home.nix
    ];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.05"; # Did you read the comment?

  wsl = {
    enable = true;
    defaultUser = username;
    startMenuLaunchers = true;
    usbip.enable = true;
    wslConf.interop.appendWindowsPath = false;

    # Enable integration with Docker Desktop (needs to be installed)
    docker-desktop.enable = true;
    useWindowsDriver = true;
    wslConf.automount.ldconfig = true;
  };

  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    autoPrune.enable = true;
    daemon.settings.features.cdi = true;
  };
  hardware.nvidia-container-toolkit = {
    enable = true;
    mount-nvidia-executables = false;
  };
  services.xserver.videoDrivers = [ "nvidia" ];
  
  programs.nix-ld.enable = true;
  environment.variables.NIX_LD_LIBRARY_PATH = lib.mkForce "/run/current-system/sw/share/nix-ld/lib:/usr/lib/wsl/lib";

  nix = {
    settings = {
      experimental-features = "nix-command flakes";
      trusted-users = [username];
      accept-flake-config = true;
      auto-optimise-store = true;
    };

    registry = {
      nixpkgs = {
        flake = inputs.nixpkgs;
      };
    };

    nixPath = [
      "nixpkgs=${inputs.nixpkgs.outPath}"
      "nixos-config=/etc/nixos/configuration.nix"
      "/nix/var/nix/profiles/per-user/root/channels"
    ];

    package = pkgs.nixVersions.stable;
    # extraOptions = ''experimental-features = nix-command flakes'';

    gc = {
      automatic = true;
      options = "--delete-older-than 7d";
    };
  };
}
