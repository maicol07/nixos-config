{ pkgs, ... }: let
  php85custom = pkgs.php85.buildEnv {
    extensions = { enabled, all }:
      enabled ++ (with all; [
        bcmath
        curl
        gd
        intl
        mbstring
        xdebug
        xsl
        yaml
        zip
      ]);
    extraConfig = ''
      xdebug.mode=debug
    '';
  };
in [
  ###### Programming languages ######
  pkgs.python3
  pkgs.nodejs_latest
  pkgs.pnpm
  pkgs.deno

  # PHP toolchain
  php85custom.out
  php85custom.packages.composer

  # SQL
  pkgs.mariadb.client
  pkgs.mycli

  ###### Formatters and linters ######
  pkgs.alejandra
  pkgs.deadnix
  pkgs.shellcheck
  pkgs.shfmt
  pkgs.statix

  ###### Utilities ######
  pkgs.asciinema
  pkgs.dive
  pkgs.dtop
  pkgs.gemini-cli
  pkgs.geminicommit
  pkgs.git-crypt
  pkgs.git-interactive-rebase-tool
  pkgs.github-copilot-cli
  pkgs.nixd
  pkgs.wakatime-cli

  ###### Other ######
  pkgs.awscli2
  pkgs.awsume
  pkgs.cruise
  pkgs.k9s
  pkgs.kubecolor
  pkgs.kubectx
  pkgs.prek
  pkgs.supabase-cli
  pkgs.terraform
]
