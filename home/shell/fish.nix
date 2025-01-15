{ pkgs, lib, ...}: {
  programs = {
    fzf.enable = true;
    fzf.enableFishIntegration = true;
    lsd.enable = true;
    lsd.enableAliases = true;
    zoxide.enable = true;
    zoxide.enableFishIntegration = true;
    broot.enable = true;
    broot.enableFishIntegration = true;
    direnv.enable = true;
    direnv.nix-direnv.enable = true;

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
        {
          gc = "nix-collect-garbage --delete-old";
          ssh = "/mnt/c/Windows/System32/OpenSSH/ssh.exe";
        }
        # navigation shortcuts
        // {
          ".." = "cd ..";
          "..." = "cd ../../";
          "...." = "cd ../../../";
          "....." = "cd ../../../../";
        };
      plugins = [
        # To be compatible with the refresh plugin we need to use the fork
        {
          name = "async-prompt";
          src = pkgs.fetchFromGitHub {
            owner = "infused-kim";
            repo = "fish-async-prompt";
            rev = "07e107635e693734652b0709dd34166820f1e6ff";
            # How to get:
            # nix-shell -p nix-prefetch-git jq --run "nix hash convert sha256:\$(nix-prefetch-git --url https://github.com/infused-kim/fish-async-prompt --quiet --rev 07e107635e693734652b0709dd34166820f1e6ff | jq -r '.sha256')"
            sha256 = "sha256-rE80IuJEqnqCIE93IzeT2Nder9j4fnhFEKx58HJUTPk=";
          };
        }
        {
          name = "autopair";
          inherit (pkgs.fishPlugins.autopair) src;
        }
        {
          name = "bd";
          inherit (pkgs.fishPlugins.fish-bd) src;
        }
        {
          name = "colored-man";
          src = pkgs.fetchFromGitHub {
            owner = "decors";
            repo = "fish-colored-man";
            rev = "1ad8fff696d48c8bf173aa98f9dff39d7916de0e";
            # How to get:
            # nix-shell -p nix-prefetch-git jq --run "nix hash convert sha256:\$(nix-prefetch-git --url https://github.com/decors/fish-colored-man --quiet --rev 1ad8fff696d48c8bf173aa98f9dff39d7916de0e | jq -r '.sha256')"
            sha256 = "sha256-uoZ4eSFbZlsRfISIkJQp24qPUNqxeD0JbRb/gVdRYlA=";
          };
        }
        # Disabled due to https://github.com/franciscolourenco/done/issues/94
        # {
        #   name = "done";
        #   inherit (pkgs.fishPlugins.done) src;
        # }
        {
          name = "forgit";
          inherit (pkgs.fishPlugins.forgit) src;
        }
        # Needs fisher, not working ATM
        # {
        #   name = "fish-ai";
        #   src = pkgs.fetchFromGitHub {
        #     owner = "Realiserad";
        #     repo = "fish-ai";
        #     rev = "v1.0.0";
        #     # How to get:
        #     # nix-shell -p nix-prefetch-git jq --run "nix hash convert sha256:\$(nix-prefetch-git --url https://github.com/Realiserad/fish-ai --quiet --rev v1.0.0 | jq -r '.sha256')"
        #     sha256 = "sha256-OnKkANNR51G34edj2HbohduaFARk6ud15N3+ULYs7s4=";
        #   };
        # }
        {
          name = "refresh-prompt-on-cmd";
          src = pkgs.fetchFromGitHub {
            owner = "infused-kim";
            repo = "fish-refresh-prompt-on-cmd";
            rev = "v1.0.0";
            # How to get:
            # nix-shell -p nix-prefetch-git jq --run "nix hash convert sha256:\$(nix-prefetch-git --url https://github.com/infused-kim/fish-refresh-prompt-on-cmd --quiet --rev v1.0.0 | jq -r '.sha256')"
            sha256 = "sha256-2+YV4yVU82c+4HKCrruJHT5w626M3D4qFLPGXaDE8zA=";
          };
        }
        {
          name = "nix-command-not-found";
          src = pkgs.fetchFromGitHub {
            owner = "kpbaks";
            repo = "nix_command_not_found.fish";
            rev = "d52d0e56b359bbd8d507b6d8650dfe3487d000ff";
            # How to get:
            # nix-shell -p nix-prefetch-git jq --run "nix hash convert sha256:\$(nix-prefetch-git --url https://github.com/kpbaks/nix_command_not_found.fish --quiet --rev d52d0e56b359bbd8d507b6d8650dfe3487d000ff | jq -r '.sha256')"
            sha256 = "sha256-VWQIeKcXyAJrxi797Vir5dnNpwJjjAdHgwFkroNspxU=";
          };
        }
        {
          name = "sponge";
          inherit (pkgs.fishPlugins.sponge) src;
        }
      ];
    };
  };

# Needs fisher, not working ATM
#   home.file = {
#     ".config/fish-ai.ini".text = "[fish-ai]
# configuration = github

# [github]
# provider = self-hosted
# server = https://models.inference.ai.azure.com
# api_key = ${secrets.fish-ai-api-key}
# model = gpt-4o-mini";
    
#     ".config/starship-minimal.toml".source = ./starship-minimal.toml;
#   };
}