{ lib, hostname, ... }: let
  syncHosts = [
    "maicol07-pc"
    "maicol07-galaxy"
  ];

  isSyncHost = builtins.elem hostname syncHosts;

  # Device IDs are required by Syncthing to pair peers.
  # Fill these values with the real IDs shown in each host's Syncthing UI.
  deviceIds = {
    maicol07-pc = "ODHC7VB-IT3PQO6-ZSO72F2-UXMZSAB-NDITHSZ-MS7HKIN-BM5DR24-PQS25QK";
    maicol07-galaxy = "WUFHAFW-IWVK633-SDQRY26-APRYUDU-TOHEGZH-ZIGLXKX-HC5HAXB-YXEIYAR";
  };

  otherHosts = builtins.filter (name: name != hostname) (builtins.attrNames deviceIds);

  localDeviceId = deviceIds.${hostname} or "";
  hasDeviceIds = localDeviceId != "";
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
      };


      devices = lib.optionalAttrs hasDeviceIds (lib.genAttrs otherHosts (name: {
        id = deviceIds.${name};
        autoAcceptFolders = true;
      }));

      folders = lib.optionalAttrs hasDeviceIds {
        projects = {
          id = "projects";
          label = "Projects";
          path = "~/Projects";
          devices = otherHosts;
        };
        studioProjects = {
          id = "studio-projects";
          label = "Studio Projects";
          path = "/mnt/c/Users/Maicol/StudioProjects";
          devices = otherHosts;
        };
      };
    };
  };

  home.activation.syncthingStignore = lib.mkIf isSyncHost (lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/Projects"
    cat > "$HOME/Projects/.stignore" <<'EOF'
**/.cache
**/.cache/**
**/.data
**/.data/**
**/.pnpm-store
**/.pnpm-store/**
**/.wireit
**/.wireit/**
**/node_modules
**/node_modules/**
**/vendor
**/vendor/**
**/public/wp
**/public/wp/**
EOF
    cat > "/mnt/c/Users/Maicol/StudioProjects/.stignore" <<'EOF'
**/.kotlin
**/.kotlin/**
**/build
**/build/**
EOF
  '');

  warnings = lib.optional (isSyncHost && !hasDeviceIds) ''
    Syncthing is enabled, but the current host device ID is not configured in home/programs/syncthing.nix.
    Set deviceIds in the configuration to sync.
  '';
}