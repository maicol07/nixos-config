{ pkgs, lib, isWsl ? false, hostname ? "", ... }: let 
php84custom = pkgs.php84.buildEnv {
      extensions = { enabled, all }:
        enabled ++ (with all; [
          bcmath
          curl
          gd
          intl
          mbstring
          opcache
          xdebug
          xsl
          yaml
          zip
        ]);
      extraConfig = ''
        xdebug.mode=debug
      '';
    };

  isServer = hostname == "maicol07-server";
  isPersonal = hostname == "maicol07-pc" || hostname == "maicol07-galaxy";

  groups = {
    common = with pkgs; [
      ###### System ######
      coreutils
      curl
      findutils
      killall
      htop

      ###### Utilities ######
      croc
      dos2unix
      du-dust
      duf
      fx
      httpie
      lsof
      nix-inspect
      procs
      sd
      tlrc
      tree
      unzip
      wget
      zip
      xcp
    ];

    # Tools specific to the server host
    server = with pkgs; [
      # KDE
      kdePackages.discover # Optional: Install if you use Flatpak or fwupd firmware update sevice
      kdePackages.sddm-kcm # Configuration module for SDDM
      # Non-KDE graphical packages
      hardinfo2 # System information and benchmarks for Linux systems
      nvidia-container-toolkit
      xorg.xauth
      xclip
    ];

    # Developer/personal tools for PCs
    personal = with pkgs; [
      ###### Programming languages ######
      python3
      nodejs_latest
      corepack_latest

      # PHP toolchain
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

      ###### Utilities ######
      asciinema
      git-crypt
      nixd
      wakatime-cli

      ###### Other ######
      awscli2
      awsume
      pre-commit
      terraform
    ] ++ lib.optionals isWsl [ pkgs.wslu ];
  };
in {
  home.packages =
    groups.common
    ++ lib.optionals isServer groups.server
    ++ lib.optionals isPersonal groups.personal;
}