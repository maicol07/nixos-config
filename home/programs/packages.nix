{ pkgs, ... }: let 
php84custom = pkgs.php84.buildEnv {
      extensions = ({enabled, all}:
        enabled ++ (with all; [
          bcmath
          curl
          gd
          intl
          mbstring
          opcache
          xdebug
          xsl
          zip
        ]));
      extraConfig = ''
        xdebug.mode=debug
      '';
    };
in {
  home.packages = with pkgs; [
    ###### System ######
    coreutils
    curl
    findutils
    killall
    htop

    ###### Utilities ######
    asciinema
    dos2unix
    du-dust
    duf
    fx
    git-crypt
    httpie
    lsof
    nix-inspect
    nixd
    procs
    sd
    tlrc
    tree
    unzip
    wakatime-cli
    wget
    wslu
    zip
    xcp

    ###### Programming languages ######
    # python
    python3

    # nodejs
    nodejs_latest
    corepack_latest
    
    # PHP
  #   php84.withExtensions ({ enabled, all }:
  # enabled ++ [ all.imagick ])
    php84custom.out
    php84custom.packages.composer

    # SQL
    mariadb-client
    
    ###### Formatters and linters ######
    alejandra # nix
    deadnix # nix
    shellcheck
    shfmt
    statix # nix

    ###### Other ######
    awscli2
    awsume
    pre-commit
    terraform
  ];
}