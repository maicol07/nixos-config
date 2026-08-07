{ pkgs, lib, ... }: let
  wrapperCommands = [ "node" "npm" "pnpm" "yarn" "npx" ];

  wrapperScript = builtins.readFile ./node-wrapper.sh;

  mkNodeWrapperScript = targetCmd:
    pkgs.writeShellScript targetCmd (builtins.replaceStrings [ "__TARGET_CMD__" ] [ targetCmd ] wrapperScript);

  nodeWrappersPackage = pkgs.runCommand "node-wrappers" {} ''
    mkdir -p "$out/bin/node-wrappers"

    ${lib.concatMapStringsSep "\n" (targetCmd: ''
      ln -s ${mkNodeWrapperScript targetCmd} "$out/bin/node-wrappers/${targetCmd}"
    '') wrapperCommands}
  '';
in {
  home.packages = [ nodeWrappersPackage ];
}
