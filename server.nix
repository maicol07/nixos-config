{pkgs, hostname}: {
  # Base server hardening/services (non-WSL)
   
   imports = [
    # Include the hardware configuration
    ./hardware-configuration.nix
   ];

  # Bootloader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  networking.hostName = hostname;
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;
  
  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "it";
    variant = "";
  };

  # Configure console keymap
  console.keyMap = "it2";

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;


  # Firewall disabled due to external one
  networking.firewall.enable = false;

  # OpenSSH hardened defaults
  services.openssh = {
    enable = true;
  openFirewall = false;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
  X11Forwarding = true;
      AllowTcpForwarding = "yes";
      AllowAgentForwarding = "yes";
      UseDns = false;
  Subsystem = "sftp /run/current-system/sw/lib/ssh/sftp-server";
      # modern key exchange/ciphers are used by default in recent NixOS
    };
  };

  # Logrotate for traditional logs (journald is separate)
  services.logrotate.enable = true;

  # Docker daemon tuning for Swarm nodes
  virtualisation.docker.daemon.settings = {
    # limit container logs to avoid filling disk
    "log-driver" = "json-file";
    "log-opts" = {
      "max-size" = "10m";
      "max-file" = "3";
    };
    # DISABLE keep containers running across daemon restarts (needed for Swarm)
    "live-restore" = false;
    # avoid address conflicts across nodes (adjust as needed)
    "default-address-pools" = [ { "base" = "10.0.0.0/8"; "size" = 24; } ];
  };

  # Auto-upgrade NixOS from this flake
  system.autoUpgrade = {
    enable = true;
    flake = "path:/etc/nixos";
    allowReboot = false; # set true if acceptable
    dates = "daily";
  };

  # Persistent journald with size cap
  services.journald.extraConfig = ''
    Storage=persistent
    SystemMaxUse=1G
  '';

  # NVIDIA drivers (server)
  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    open = true;
    nvidiaSettings = true;
    powerManagement.enable = false;
  };

  # XRDP for headless RDP logins
  services.xrdp = {
    enable = true;
    openFirewall = false;
    defaultWindowManager = "gnome-session";
  };

  # Cockpit (web admin UI on port 9090)
  services.cockpit.enable = true;

  # Desktop environment for local and XRDP sessions: GNOME on Xorg
  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    # Force Xorg for XRDP compatibility
    displayManager.gdm.wayland = false;
    desktopManager.gnome.enable = true;
  };
}
