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
  };

  outputs = inputs:
    with inputs; let
      secrets = builtins.fromJSON (builtins.readFile "${self}/secrets.json");

      nixpkgsWithOverlays = system: (import nixpkgs {
        inherit system;

        config = {
          allowUnfree = true;
          permittedInsecurePackages = [
          ];
        };

        overlays = [
          nur.overlays.default
          (final: prev: {
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
        home-manager.extraSpecialArgs = args;
      };

      argDefaults = {
        inherit secrets inputs self nix-index-database;
        channels = {
          inherit nixpkgs /* nixpkgs-unstable */;
        };
      };

      mkNixosConfiguration = {
        system ? "x86_64-linux",
        hostname,
        username,
        args ? {},
        modules,
      }: let
        specialArgs = argDefaults // {inherit hostname username;} // args;
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

      nixosConfigurations.maicol07-pc = mkNixosConfiguration {
        hostname = "maicol07-pc";
        username = "maicol07";
        modules = [
          nixos-wsl.nixosModules.wsl
          ./wsl.nix
        ];
      };
    };
}
