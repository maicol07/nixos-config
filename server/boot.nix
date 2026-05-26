{ pkgs, lib, ... }: {
  # Bootloader: systemd-boot (UEFI)
  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.efi.canTouchEfiVariables = true;

  # Secure Boot (lanzaboote + sbctl)
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl";
  };
  systemd.tmpfiles.rules = [ "d /var/lib/sbctl 0700 root root -" ];

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernel.sysctl = {
    "vm.swappiness" = 10;
    "fs.inotify.max_user_watches" = 524288;
  };
}
