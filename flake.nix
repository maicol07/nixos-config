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
  
    lfk.url = "github:janosmiko/lfk";

    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

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
            # GCC 16 defaults to C++20, whose std::lerp conflicts with rxvt's helper.
            rxvt-unicode-unwrapped = prev.rxvt-unicode-unwrapped.overrideAttrs (_: {
              CXXFLAGS = "-O2 -std=gnu++17";
            });

            # GCC 16 provides <simd>, but Contour builds as C++23 and needs the experimental API.
            contour = prev.contour.overrideAttrs (oldAttrs: {
              postPatch = (oldAttrs.postPatch or "") + ''
                substituteInPlace src/vtbackend/Image.cpp \
                  --replace-fail '#if __has_include(<simd>)' \
                    '#if __has_include(<simd>) && __cplusplus >= 202600L'
              '';
            });

            fastfetch = prev.fastfetch.overrideAttrs (oldAttrs: {
              buildInputs =
                if system == "x86_64-linux" then
                  (oldAttrs.buildInputs or []) ++ [ prev.directx-headers ]
                else
                  oldAttrs.buildInputs or [];

              cmakeFlags =
                if system == "x86_64-linux" then
                  (oldAttrs.cmakeFlags or []) ++ [ (nixpkgs.lib.cmakeBool "ENABLE_DIRECTX_HEADERS" true) ]
                else
                  oldAttrs.cmakeFlags or [];
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
        inherit inputs self nix-index-database lfk;
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
        roles = {
          isServer = hostname == "maicol07-server";
          isPersonal = builtins.elem hostname [ "maicol07-pc" "maicol07-galaxy" ];
          isDarwin = false;
        };
        specialArgs = argDefaults // { inherit hostname username isWsl; } // roles // args;
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

      mkDarwinConfiguration = {
        system ? "aarch64-darwin", # Use "x86_64-darwin" if you have an Intel Mac
        hostname,
        username,
        isWsl ? false,
        args ? {},
        modules,
      }: let
        roles = {
          isServer = false;
          isPersonal = true;
          isDarwin = true;
        };
        specialArgs = argDefaults // { inherit hostname username isWsl; } // roles // args;
      in
        nix-darwin.lib.darwinSystem {
          inherit system specialArgs;
          pkgs = nixpkgsWithOverlays system;
          modules =
            [
              (configurationDefaults specialArgs)
              home-manager.darwinModules.home-manager
            ]
            ++ modules;
        };

      mkWslConfig = hostname:
        mkNixosConfiguration {
          inherit hostname;
          username = "maicol07";
          isWsl = true;
          modules = [
            ./common.nix
            ./nixos.nix
            nixos-wsl.nixosModules.wsl
            ./wsl.nix
          ];
        };
    in {
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;

      packages.x86_64-linux = let
        pkgs = nixpkgsWithOverlays "x86_64-linux";
        windowsFor = hostname: import ./windows {
          inherit pkgs;
          home = self.nixosConfigurations.${hostname}.config.home-manager.users.maicol07;
        };
      in {
        sys = import ./pkgs/sys { inherit pkgs; };
        windows-dotfiles-maicol07-pc = windowsFor "maicol07-pc";
        windows-dotfiles-maicol07-galaxy = windowsFor "maicol07-galaxy";
      };

      apps.x86_64-linux.sys = {
        type = "app";
        program = "${self.packages.x86_64-linux.sys}/bin/sys";
      };

      checks.x86_64-linux.windows-dotfiles = let
        pkgs = nixpkgsWithOverlays "x86_64-linux";
      in pkgs.runCommand "windows-dotfiles-tests" {
        nativeBuildInputs = [ pkgs.python3 pkgs.git ];
      } ''
        export PYTHONDONTWRITEBYTECODE=1
        export WINDOWS_DOTFILES=${self.packages.x86_64-linux.windows-dotfiles-maicol07-pc}
        export SYS_SCRIPTS=${./scripts}
        export AI_INSTRUCTIONS=${./home/AGENTS.md}
        python3 ${./tests/windows-dotfiles.py}
        touch "$out"
      '';

      nixosConfigurations = {
        maicol07-pc = mkWslConfig "maicol07-pc";

        maicol07-galaxy = mkWslConfig "maicol07-galaxy";

        maicol07-server = mkNixosConfiguration {
          hostname = "maicol07-server";
          username = "maicol07";
          isWsl = false;
          modules = [
            ./common.nix
            ./nixos.nix
            ./server.nix
          ];
        };
      };

      darwinConfigurations = {
        "MAICOL-MAC" = mkDarwinConfiguration {
          hostname = "MAICOL-MAC";
          username = "maicol07"; # Ensure this matches your macOS short username
          modules = [
            ./common.nix
            ./darwin
          ];
        };
      };
    };
}
