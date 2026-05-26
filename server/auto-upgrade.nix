{ ... }: {
  system.autoUpgrade = {
    enable = true;
    flake = "path:/etc/nixos";
    allowReboot = false;
    dates = "daily";
  };

  services.journald.extraConfig = ''
    Storage=persistent
    SystemMaxUse=1G
  '';

  services.logrotate.enable = true;
}
