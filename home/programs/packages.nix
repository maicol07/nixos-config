{ pkgs, lib, isWsl ? false, hostname ? "", ... }: let 
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
      dust
      duf
      fresh-editor
      fx
      grc
      httpie
      jq
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
      epiphany

      ###### LSP for Fresh Editor ######
      bash-language-server
    ];

    # Tools specific to the server host
    server = with pkgs; [
      # KDE
      kdePackages.discover # Optional: Install if you use Flatpak or fwupd firmware update sevice
      kdePackages.sddm-kcm # Configuration module for SDDM
      # Non-KDE graphical packages
      hardinfo2 # System information and benchmarks for Linux systems
      dmidecode # DMI table decoder
      lsscsi # List SCSI devices (including SATA, NVMe, etc.)
      lshw-gui # GUI for lshw
      xorg.xauth
      xclip
    ];

    # Developer/personal tools for PCs
    personal = with pkgs; [
      ###### Programming languages ######
      python3
      nodejs_latest
      pnpm
      deno

      # PHP toolchain
      php85custom.out
      php85custom.packages.composer

      # SQL
      mariadb.client
      mycli

      ###### Formatters and linters ######
      alejandra # nix
      deadnix # nix
      shellcheck
      shfmt
      statix # nix

      ###### Utilities ######
      asciinema
      copilot-cli
      dive
      dtop
      gemini-cli
      geminicommit
      git-crypt
      git-interactive-rebase-tool
      nixd
      wakatime-cli

      ###### Other ######
      awscli2
      awsume
      cruise
      k9s
      kubecolor
      kubectx
      prek
      supabase-cli
      terraform
    ] ++ lib.optionals isWsl [ pkgs.wslu ];
  };
in {
  home.packages =
    groups.common
    ++ lib.optionals isServer groups.server
    ++ lib.optionals isPersonal groups.personal;
}