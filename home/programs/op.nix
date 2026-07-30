{ pkgs, ... }: let
  opScript = pkgs.writeShellScriptBin "op" (builtins.readFile ./op.sh);
in {
  home.packages = [ opScript ];
}
