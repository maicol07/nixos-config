{ username, hostname, pkgs, inputs, ... }: {
  # Common system configuration shared across all hosts
  time.timeZone = "Europe/Rome";

  networking.hostName = hostname;

  programs.fish.enable = true;
  environment.shells = [ pkgs.fish ];

  users.users.${username} = {
    shell = pkgs.fish;
  };

  # Home Manager wiring for the user
  home-manager.users.${username} = {
    imports = [ ./home.nix ];
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
}
