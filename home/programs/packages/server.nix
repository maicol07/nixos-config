{ pkgs, ... }: with pkgs; [
  epiphany
  # KDE
  kdePackages.discover
  kdePackages.sddm-kcm
  # Non-KDE graphical packages
  hardinfo2
  dmidecode
  lsscsi
  lshw-gui
  parted
  smartmontools
  usbutils
  xauth
  xclip
]
