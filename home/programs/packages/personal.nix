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
in with pkgs; [
  ###### Programming languages ######
  python3
  nodejs_latest
  pnpm
  deno
  bun

  # PHP toolchain
  php85custom.out
  php85custom.packages.composer

  # SQL
  mariadb.client
  mycli

  ###### Formatters and linters ######
  alejandra
  deadnix
  shellcheck
  shfmt
  statix

  ###### Utilities ######
  asciinema
  antigravity-cli
  claude-code
  dive
  dtop
  geminicommit
  git-crypt
  git-interactive-rebase-tool
  gnumake
  nixd
  wakatime-cli

  ###### Other ######
  awscli2
  awsume
  kubernetes-helm
] ++ lib.optionals (!pkgs.stdenv.isDarwin) [
  cruise
] ++ (with pkgs; [
  k9s
  kubecolor
  kubectx
  prek
  supabase-cli
  terraform
])
