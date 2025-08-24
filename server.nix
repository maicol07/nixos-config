_: {
  # Base server hardening/services (non-WSL)

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
      UseDNS = "no";
  Subsystem = "sftp /run/current-system/sw/lib/ssh/sftp-server";
      # modern key exchange/ciphers are used by default in recent NixOS
    };
  };

  # Fail2ban for SSH/others (uses journald by default)
  security.fail2ban = {
    enable = true;
    bantime = "1h"; # optional: adjust as needed
    ignoreIP = [ "127.0.0.1/8" "::1" ];
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
    # keep containers running across daemon restarts
    "live-restore" = true;
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
  hardware.opengl.enable = true;
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

  # Webmin (admin UI on port 10000)
  services.webmin.enable = true;

  # SSH X11 forwarding and SFTP configured above in services.openssh.settings

  # Desktop environment for local and XRDP sessions: GNOME on Xorg
  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    # Force Xorg for XRDP compatibility
    displayManager.gdm.wayland = false;
    desktopManager.gnome.enable = true;
  };
}
