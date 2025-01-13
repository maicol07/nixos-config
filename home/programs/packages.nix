{ pkgs, ... }: {
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
    php84
    php84Packages.composer
    php84Extensions.bcmath
    php84Extensions.curl
    php84Extensions.gd
    php84Extensions.intl
    php84Extensions.mbstring
    php84Extensions.opcache
    php84Extensions.xml
    php84Extensions.zip
    
    ###### Formatters and linters ######
    alejandra # nix
    deadnix # nix
    shellcheck
    shfmt
    statix # nix

    ###### Other ######
    awscli2
    httpie
    terraform
  ];
}