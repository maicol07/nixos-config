{ pkgs, ... }: {
  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    branch = "legacy_580";
    modesetting.enable = true;
    open = false; # Needed to support Quadro K620
    nvidiaSettings = true;
    powerManagement.enable = false;
  };
  hardware.nvidia-container-toolkit.enable = true;
  services.udisks2.enable = true;

  services.smartd = {
    enable = true;
    notifications.x11.enable = true;
  };
}
