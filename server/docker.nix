{ ... }: {
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
    daemon.settings = {
      features.cdi = true;
      "log-driver" = "json-file";
      "log-opts" = {
        "max-size" = "10m";
        "max-file" = "3";
      };
      "live-restore" = false;
    };
  };
}
