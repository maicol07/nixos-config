{ lib, hostname, ... }: let
  syncHosts = [
    "maicol07-pc"
    "maicol07-galaxy"
  ];

  isSyncHost = builtins.elem hostname syncHosts;

  otherHost =
    if hostname == "maicol07-pc" then
      "maicol07-galaxy"
    else
      "maicol07-pc";

  # Device IDs are required by Syncthing to pair peers.
  # Fill these values with the real IDs shown in each host's Syncthing UI.
  deviceIds = {
    maicol07-pc = "ODHC7VB-IT3PQO6-ZSO72F2-UXMZSAB-NDITHSZ-MS7HKIN-BM5DR24-PQS25QK";
    maicol07-galaxy = "AZIYINP-TDJRTZW-QDCVEAF-RHCZIPO-25YA46Z-QQBUNTN-2DST3FS-CTNINQN";
  };

  localDeviceId = deviceIds.${hostname} or "";
  remoteDeviceId = deviceIds.${otherHost} or "";
  hasDeviceIds = localDeviceId != "" && remoteDeviceId != "";
in {
  services.syncthing = lib.mkIf isSyncHost {
    enable = true;
    overrideDevices = true;
    overrideFolders = true;

    settings = {
      options = {
        # Disable telemetry prompt in headless/user-service setups.
        urAccepted = -1;

        # Disable QUIC completely to avoid crashes on this setup.
        # Use only TCP for both listening and dialing.
        listenAddresses = [ "tcp://0.0.0.0:22000" ];
        quicEnabled = false;
      };


      devices = lib.optionalAttrs hasDeviceIds {
        ${otherHost} = {
          id = remoteDeviceId;
          autoAcceptFolders = true;
        };
      };

      folders = lib.optionalAttrs hasDeviceIds {
        projects = {
          id = "projects";
          label = "Projects";
          path = "~/Projects";
          devices = [ otherHost ];
        };
      };
    };
  };

  warnings = lib.optional (isSyncHost && !hasDeviceIds) ''
    Syncthing is enabled, but device IDs are not configured in home/programs/syncthing.nix.
    Set deviceIds.maicol07-pc and deviceIds.maicol07-galaxy to sync ~/Projects.
  '';
}