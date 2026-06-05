{ lib, ... }: {
  services.cockpit = {
    enable = true;
    settings = {
      WebService = {
        Origins = lib.mkForce "https://192.168.1.111:9090 wss://192.168.1.111:9090";
      };
    };
  };
}
