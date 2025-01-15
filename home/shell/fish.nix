{ secrets, pkgs, ...}: {
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

        fish_add_path $HOME/.config/composer/vendor/bin

        # X410
        export DISPLAY=localhost:0.0

        # set -U fish_greeting

        #
        # Async Prompt
        #

        # Setup the synchronous prompt that is displayed immediately while the async
        # prompt is loading.
        # set -g STARSHIP_CONFIG_MINIMAL $HOME/.config/starship-minimal.toml

        # function fish_prompt_loading_indicator
        #   STARSHIP_CONFIG=$STARSHIP_CONFIG_MINIMAL starship prompt
        # end

        # function fish_prompt_right_loading_indicator
        #   STARSHIP_CONFIG=$STARSHIP_CONFIG_MINIMAL starship prompt --right
        # end

        # Disable async prompt
        # set -g async_prompt_enable 0

        # Fix incompatibility with zoxide. Source: https://github.com/acomagu/fish-async-prompt/issues/77#issuecomment-2132709455
        function fish_focus_in --on-event fish_focus_in
            __async_prompt_fire
            # commandline -f paint  # Not sure whether this helps or hurts.
        end

        function fish_right_prompt
            rpoc_time
        end
      '';
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
          name = "bat";
          src = pkgs.fetchFromGitHub {
            owner = "givensuman";
            repo = "fish-bat";
            rev = "a70c62c5f059b0a33a7185d27bf1856f36218a20";
            # How to get:
            # nix-shell -p nix-prefetch-git jq --run "nix hash convert sha256:\$(nix-prefetch-git --url https://github.com/givensuman/fish-bat --quiet --rev main | jq -r '.sha256')"
            sha256 = "sha256-O0RTaTmtP+Nxns+97CDGUYWX+EpW1mSDsJD6MY/DQwI=";
          };
        }
        {
          name = "bd";
          inherit (pkgs.fishPlugins.fish-bd) src;
        }
        {
          name = "colored-man-pages";
          inherit (pkgs.fishPlugins.colored-man-pages) src;
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
        {
          name = "sudope";
          inherit (pkgs.fishPlugins.plugin-sudope) src;
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