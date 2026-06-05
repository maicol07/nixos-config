{ pkgs, hostname, username, lib, ... }: {
  imports =
    (if builtins.pathExists ./hardware/${hostname}/hardware-configuration.nix then
      [ ./hardware/${hostname}/hardware-configuration.nix ]
     else
      []
    )
    ++ [
      ./server/boot.nix
      ./server/networking.nix
      ./server/hardware.nix
      ./server/desktop.nix
      ./server/docker.nix
      ./server/cockpit.nix
      ./server/auto-upgrade.nix
    ];
}
