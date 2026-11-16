{ pkgs, lib, isDarwin ? false, ... }:
let
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
in {
  home.packages = with pkgs; [
    ###### Programming languages ######
    uv
    bun

    # PHP toolchain
    php85custom.out
    php85custom.packages.composer

    # SQL
    mycli
    pgcli

    ###### Formatters and linters ######
    alejandra
    deadnix
    shellcheck
    shfmt
    statix

    ###### Utilities ######
    asciinema
    claude-code
    dive
    dtop
    geminicommit
    git-crypt
    git-interactive-rebase-tool
    gnumake
    nixd
    openssl
    wakatime-cli

    ###### Other ######
    awscli2
    kubernetes-helm
    ssm-session-manager-plugin
  ] ++ lib.optionals (!isDarwin) [
    cruise
  ] ++ (with pkgs; [
    glab
    k9s
    kubecolor
    kubectx
    prek
    terraform
    terraform-docs
    terragrunt
  ]);
}
