{ username, hostname, pkgs, inputs, ... }: {
  # Common system configuration shared across all hosts
  time.timeZone = "Europe/Rome";

  # Select internationalisation properties.
  i18n.defaultLocale = "it_IT.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "it_IT.UTF-8";
    LC_IDENTIFICATION = "it_IT.UTF-8";
    LC_MEASUREMENT = "it_IT.UTF-8";
    LC_MONETARY = "it_IT.UTF-8";
    LC_NAME = "it_IT.UTF-8";
    LC_NUMERIC = "it_IT.UTF-8";
    LC_PAPER = "it_IT.UTF-8";
    LC_TELEPHONE = "it_IT.UTF-8";
    LC_TIME = "it_IT.UTF-8";
  };

  networking.hostName = hostname;

  programs.fish.enable = true;
  environment.pathsToLink = [ "/share/fish" ];
  environment.shells = [ pkgs.fish ];
  environment.enableAllTerminfo = true;

  security.sudo.wheelNeedsPassword = false;

  users.users.${username} = {
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups = [
      "wheel"
      "docker"
      "networkmanager"
    ];
  };

  # Home Manager wiring for the user
  home-manager.users.${username} = {
    imports = [ ./home.nix ];
  };

  # Keep docker available on all hosts (tweak per-host as needed)
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
    autoPrune.enable = true;
    daemon.settings.features.cdi = true;
  };

  # Nix settings common to all hosts
  nix = {
    settings = {
      experimental-features = "nix-command flakes";
      trusted-users = [ username ];
      accept-flake-config = true;
      auto-optimise-store = true;
    };

    registry.nixpkgs.flake = inputs.nixpkgs;

    nixPath = [
      "nixpkgs=${inputs.nixpkgs.outPath}"
      "nixos-config=/etc/nixos/configuration.nix"
      "/nix/var/nix/profiles/per-user/root/channels"
    ];

    package = pkgs.nixVersions.stable;

    gc = {
      automatic = true;
      options = "--delete-older-than 7d";
    };
  };

  # This value determines the NixOS release from which defaults are taken
  system.stateVersion = "24.05"; # Keep as first install release
}
