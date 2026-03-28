{
  username,
  pkgs,
  lib,
  config,
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
  
  hardware = lib.mkMerge [
    (lib.mkIf (config.networking.hostName == "maicol07-pc") {
      nvidia.open = true;
      nvidia-container-toolkit = {
        enable = true;
        mount-nvidia-executables = false;
      };
    })
    (lib.mkIf (config.networking.hostName == "maicol07-galaxy") {
      graphics = {
        enable = true;
        extraPackages = with pkgs; [
          intel-media-driver
          intel-compute-runtime
          vpl-gpu-rt
        ];
      };
    })
  ];
  services.xserver.videoDrivers = lib.mkMerge [
    (lib.mkIf (config.networking.hostName == "maicol07-pc") [ "nvidia" ])
    (lib.mkIf (config.networking.hostName == "maicol07-galaxy") [ "intel" ])
  ];
  
  programs.nix-ld.enable = true;
  environment.variables.NIX_LD_LIBRARY_PATH = lib.mkForce "/run/current-system/sw/share/nix-ld/lib:/usr/lib/wsl/lib";

  # Raise inotify limits for large trees (e.g. Syncthing on ~/Projects).
  boot.kernel.sysctl = {
    "fs.inotify.max_user_watches" = 1048576;
    "fs.inotify.max_user_instances" = 8192;
    "fs.inotify.max_queued_events" = 32768;
  };
}
