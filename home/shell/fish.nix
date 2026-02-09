{ pkgs, lib, isWsl ? false, ...}: {
  programs = {
    fzf = {
      enable = true;
      enableFishIntegration = true;
    };
    lsd = {
      enable = true;
      enableFishIntegration = true;
      settings = {
        header = true;
        hyperlink = "auto";
      };
    };
    zoxide = {
      enable = true;
      enableFishIntegration = true;
    };
    broot = {
      enable = true;
      enableFishIntegration = true;
    };
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    starship = {
      enable = true;
      enableInteractive = false;
      settings = pkgs.lib.importTOML ./starship.toml;
    };

    fish = {
      enable = true;
      interactiveShellInit = ''
        ${pkgs.any-nix-shell}/bin/any-nix-shell fish --info-right | source
      '' + lib.readFile ./config.fish;
      functions = {
        refresh = "source $HOME/.config/fish/config.fish";
      };
      shellAbbrs =
        ({
          gc = "nix-collect-garbage --delete-old";
        }
        // lib.optionalAttrs isWsl {
          ssh = "/mnt/c/Windows/System32/OpenSSH/ssh.exe";
        })
        # navigation shortcuts
        // {
          ".." = "cd ..";
          "..." = "cd ../../";
          "...." = "cd ../../../";
          "....." = "cd ../../../../";
        };
      plugins = [
        {
          name = "artisan-completion";
          src = pkgs.fetchFromGitHub {
            owner = "adriaanzon";
            repo = "fish-artisan-completion";
            rev = "8e8d726b3862fcb972abb652fb8c1a9fb9207a64";
            # How to get:
            # nix-shell -p nix-prefetch-git jq --run "nix hash convert sha256:\$(nix-prefetch-git --url https://github.com/adriaanzon/fish-artisan-completion --quiet --rev 8e8d726b3862fcb972abb652fb8c1a9fb9207a64 | jq -r '.sha256')"
            sha256 = "sha256-+LKQVuWORJcyuL/YZ3B86hpbV4rbSkj41Y9qgwXZXu4=";
          };
        }
        {
          name = "autopair";
          inherit (pkgs.fishPlugins.autopair) src;
        }
        {
          name = "aws";
          inherit (pkgs.fishPlugins.aws) src;
        }
        {
          name = "bd";
          inherit (pkgs.fishPlugins.fish-bd) src;
        }
        {
          name = "colored-man";
          inherit (pkgs.fishPlugins.colored-man-pages) src;
        }
        # Disabled due to https://github.com/franciscolourenco/done/issues/94
        # {
        #   name = "done";
        #   inherit (pkgs.fishPlugins.done) src;
        # }
        {
          name = "fifc";
          inherit (pkgs.fishPlugins.fifc) src;
        }
        {
          name = "forgit";
          inherit (pkgs.fishPlugins.forgit) src;
        }
        {
          name = "grc";
          inherit (pkgs.fishPlugins.forgit) src;
        }
        # Needs fisher, not working ATM
        {
          name = "fish-ai";
          src = pkgs.fetchFromGitHub {
            owner = "Realiserad";
            repo = "fish-ai";
            rev = "v2.9.3";
            # How to get: Next build will show the correct hash
            hash = "sha256-zySfn76xC9an6QcfaThgN1FErPeriNxKhJhO22K+2nY=";
          };
        }
        {
          name = "puffer";
          inherit (pkgs.fishPlugins.puffer) src;
        }
        {
          name = "sponge";
          src = pkgs.fetchFromGitHub {
            owner = "halostatue";
            repo = "sponge";
            tag = "v1.2.0";
            # How to get: Next build will show the correct hash
            sha256 = "sha256-3Qpt4guoxh9Ag61WasjCYlxSI0W0XG8uWYBertPB+Ck=";
          };
        }
        {
          name = "you-should-use";
          inherit (pkgs.fishPlugins.fish-you-should-use) src;
        }
      ];
    };
  };

# Needs fisher, not working ATM
  home.file = {
    ".config/starship-minimal.toml".source = ./starship-minimal.toml;
  };
}