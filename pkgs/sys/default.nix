{pkgs}: let
  scripts = ../../scripts;
in
  pkgs.writeShellApplication {
    name = "sys";
    runtimeInputs = [pkgs.nix pkgs.nixos-rebuild pkgs.python3 pkgs.coreutils];
    text = ''
      export PYTHONDONTWRITEBYTECODE=1
      exec python3 ${scripts}/sys.py "$@"
    '';
  }
