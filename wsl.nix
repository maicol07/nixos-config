{
  username,
  lib,
  ...
}: {
  wsl = {
    enable = true;
    defaultUser = username;
    startMenuLaunchers = true;
    usbip.enable = true;
    wslConf.interop.appendWindowsPath = false;

    # Enable integration with Docker Desktop (needs to be installed)
    docker-desktop.enable = true;
    useWindowsDriver = true;
    wslConf.automount.ldconfig = true;
  };
  
  hardware = {
    nvidia.open = true;
    nvidia-container-toolkit = {
      enable = true;
      mount-nvidia-executables = false;
    };
  };
  services.xserver.videoDrivers = [ "nvidia" ];
  
  programs.nix-ld.enable = true;
  environment.variables.NIX_LD_LIBRARY_PATH = lib.mkForce "/run/current-system/sw/share/nix-ld/lib:/usr/lib/wsl/lib";
}
