{ pkgs, ... }: {
  services.xserver = {
    enable = true;
    xkb.layout = "it";
    xkb.variant = "";
  };

  console.keyMap = "it2";

  services.printing.enable = true;

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };
  services.desktopManager.plasma6.enable = true;

  environment.plasma6.excludePackages = with pkgs; [
    kdePackages.elisa
    kdePackages.kdepim-runtime
    kdePackages.kmahjongg
    kdePackages.kmines
    kdePackages.konversation
    kdePackages.kpat
    kdePackages.ksudoku
    kdePackages.ktorrent
    mpv
  ];

  environment.systemPackages = pkgs.lib.mkAfter [ pkgs.sbctl pkgs.kdePackages.krdp ];
}
