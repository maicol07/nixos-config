{ pkgs, ... }: [
  pkgs.epiphany
  # KDE
  pkgs.kdePackages.discover
  pkgs.kdePackages.sddm-kcm
  # Non-KDE graphical packages
  pkgs.hardinfo2
  pkgs.dmidecode
  pkgs.lsscsi
  pkgs.lshw-gui
  pkgs.smartmontools
  pkgs.xorg.xauth
  pkgs.xclip
]
