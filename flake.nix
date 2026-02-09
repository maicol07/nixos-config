{
  description = "NixOS configuration";

inputs = {
  # nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
  nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  home-manager.url = "github:nix-community/home-manager/master";
  home-manager.inputs.nixpkgs.follows = "nixpkgs";

  nur.url = "github:nix-community/NUR";

  nixos-wsl.url = "github:nix-community/NixOS-WSL";
  nixos-wsl.inputs.nixpkgs.follows = "nixpkgs";

  nix-index-database.url = "github:Mic92/nix-index-database";
  nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
  lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.3";

      # Optional but recommended to limit the size of your system closure.
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs:
    with inputs; let
      nixpkgsWithOverlays = system: (import nixpkgs {
        inherit system;

        config = {
          allowUnfree = true;
          permittedInsecurePackages = [
          ];
        };

        overlays = [
          nur.overlays.default
          (_: prev: {
            fastfetch = prev.fastfetch.overrideAttrs (oldAttrs: {
              buildInputs =
                if system == "x86_64-linux" then
                  oldAttrs.buildInputs ++ [ prev.directx-headers ]
                else
                  oldAttrs.buildInputs;

              cmakeFlags =
                if system == "x86_64-linux" then
                  oldAttrs.cmakeFlags ++ [ (nixpkgs.lib.cmakeBool "ENABLE_DIRECTX_HEADERS" true) ]
                else
                  oldAttrs.cmakeFlags;
            });
          })
        ];
      });

      configurationDefaults = args: {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.backupFileExtension = "hm-backup";
  # Pass flake-level special args (hostname, username, isWsl, etc.) to HM modules
  home-manager.extraSpecialArgs = args;
      };

      argDefaults = {
        inherit inputs self nix-index-database;
        channels = {
          inherit nixpkgs /* nixpkgs-unstable */;
        };
      };

      mkNixosConfiguration = {
        system ? "x86_64-linux",
        hostname,
        username,
        isWsl ? false,
        args ? {},
        modules,
      }: let
        specialArgs = argDefaults // { inherit hostname username isWsl; } // args;
      in
        nixpkgs.lib.nixosSystem {
          inherit system specialArgs;
          pkgs = nixpkgsWithOverlays system;
          modules =
            [
              (configurationDefaults specialArgs)
              home-manager.nixosModules.home-manager
            ]
            ++ modules;
        };
    in {
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;

      nixosConfigurations = {
        maicol07-pc = mkNixosConfiguration {
          hostname = "maicol07-pc";
          username = "maicol07";
          isWsl = true;
          modules = [
            ./common.nix
            nixos-wsl.nixosModules.wsl
            ./wsl.nix
          ];
        };

        maicol07-galaxy = mkNixosConfiguration {
          hostname = "maicol07-galaxy";
          username = "maicol07";
          isWsl = true;
          modules = [
            ./common.nix
            nixos-wsl.nixosModules.wsl
            ./wsl.nix
          ];
        };

        maicol07-server = mkNixosConfiguration {
          hostname = "maicol07-server";
          username = "maicol07";
          isWsl = false;
          modules = [
            ./common.nix
            lanzaboote.nixosModules.lanzaboote
            ./server.nix
          ];
        };
      };
    };
}
