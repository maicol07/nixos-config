{
  config,
  lib,
  pkgs,
  username,
  ...
}: let
  cfg = config.wsl.windowsHello;
  package = pkgs.callPackage ../pkgs/wsl-hello-sudo {};
  windowsDrive = "${config.wsl.wslConf.automount.root}/c";
  powershell = "${windowsDrive}/Windows/System32/WindowsPowerShell/v1.0/powershell.exe";
  launcher = pkgs.writeShellApplication {
    name = "wsl-hello-authenticate";
    runtimeInputs = [pkgs.coreutils];
    text = ''
      if [[ -n "''${SSH_CONNECTION:-}''${SSH_CLIENT:-}''${SSH_TTY:-}" ]] ||
         [[ ! -S "''${WSL_INTEROP:-}" ]] ||
         ! ${pkgs.gnugrep}/bin/grep -qx enabled /proc/sys/fs/binfmt_misc/WSLInterop; then
        exit 1
      fi
      work=$(mktemp -d)
      trap 'rm -rf "$work"' EXIT
      # Redirect Windows output to files so an orphan cannot hold PAM's pipe open.
      timeout --kill-after=2s 5s ${lib.escapeShellArg powershell} -NoProfile -NonInteractive \
        -Command '[Environment]::GetFolderPath("LocalApplicationData")' < /dev/null > "$work/localappdata"
      localappdata=$(tr -d '\r\n' < "$work/localappdata")
      bridge="$(/sbin/wslpath -u "$localappdata")/Programs/wsl-hello-sudo/WindowsHelloBridge.exe"
      [[ -x "$bridge" ]]
      timeout --kill-after=2s 30s "$bridge" "$@" > "$work/signature"
      cat "$work/signature"
    '';
  };
  bootstrap = pkgs.writeShellApplication {
    name = "wsl-hello-bootstrap";
    runtimeInputs = [pkgs.coreutils pkgs.openssl];
    text = ''
      [[ $(id -un) == ${lib.escapeShellArg username} ]] || {
        echo 'Run as the configured Linux user, without sudo.' >&2
        exit 1
      }
      [[ $# == 1 ]] || {
        echo 'Usage: wsl-hello-bootstrap OUTPUT_PUBLIC_KEY.pem' >&2
        exit 1
      }
      destination=$(realpath -m "$1")
      localappdata=$(${lib.escapeShellArg powershell} -NoProfile -NonInteractive \
        -Command '[Environment]::GetFolderPath("LocalApplicationData")' | tr -d '\r\n')
      directory="$(/sbin/wslpath -u "$localappdata")/Programs/wsl-hello-sudo"
      mkdir -p "$directory"
      if [[ -e "$directory/WindowsHelloBridge.exe" ]]; then
        cmp -s ${package.bridge}/share/wsl-hello-sudo/WindowsHelloBridge.exe "$directory/WindowsHelloBridge.exe" || {
          echo 'A different Windows bridge already exists; back it up before upgrading.' >&2
          exit 1
        }
      else
        install -m755 ${package.bridge}/share/wsl-hello-sudo/WindowsHelloBridge.exe "$directory/WindowsHelloBridge.exe"
      fi
      cd "$directory"
      ./WindowsHelloBridge.exe creator ${lib.escapeShellArg "pam_wsl_hello_${username}"}
      openssl pkey -pubin -in ${lib.escapeShellArg "pam_wsl_hello_${username}.pem"} -noout
      mkdir -p "$(dirname "$destination")"
      # Never enroll a key automatically into the active root-owned PAM configuration.
      if [[ -e "$destination" ]]; then
        cmp -s ${lib.escapeShellArg "pam_wsl_hello_${username}.pem"} "$destination" || {
          echo 'A different public key already exists; review the new key before replacing it.' >&2
          exit 1
        }
      else
        install -m644 ${lib.escapeShellArg "pam_wsl_hello_${username}.pem"} "$destination"
      fi
      echo "Public key exported to $destination. Review it, then rebuild NixOS."
    '';
  };
in {
  options.wsl.windowsHello = {
    enable = lib.mkEnableOption "Windows Hello for sudo, with Linux password fallback";
    publicKey = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Public PEM key exported by wsl-hello-bootstrap. Null leaves password authentication available before enrollment.";
    };
  };
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.wsl.enable && config.wsl.wslConf.interop.enabled && config.wsl.wslConf.automount.enabled;
        message = "Windows Hello sudo requires WSL, interop and automounted Windows drives.";
      }
      {
        assertion = pkgs.stdenv.hostPlatform.system == "x86_64-linux";
        message = "The pinned Windows Hello bridge release supports x86_64 only.";
      }
    ];
    security.sudo = {
      wheelNeedsPassword = lib.mkForce true;
      extraConfig = ''
        Defaults env_keep += "WSL_INTEROP SSH_CONNECTION SSH_CLIENT SSH_TTY"
      '';
    };
    security.pam.services.sudo.rules.auth.windows_hello = {
      order = config.security.pam.services.sudo.rules.auth.unix.order - 10;
      control = "sufficient";
      modulePath = "${package}/lib/security/pam_wsl_hello.so";
    };
    environment.etc =
      {
        "pam_wsl_hello/config".source = (pkgs.formats.toml {}).generate "wsl-hello-config" {
          authenticator_path = "${launcher}/bin/wsl-hello-authenticate";
          win_mnt = windowsDrive;
        };
      }
      // lib.optionalAttrs (cfg.publicKey != null) {
        "pam_wsl_hello/public_keys/pam_wsl_hello_${username}.pem".source = cfg.publicKey;
      };
    system.build.wslWindowsHello = pkgs.symlinkJoin {
      name = "wsl-windows-hello";
      paths = [package launcher bootstrap];
    };
    environment.systemPackages = [bootstrap];
  };
}
