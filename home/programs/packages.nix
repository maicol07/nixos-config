{ pkgs, lib, hostname ? "", ... }:
let
  isServer = hostname == "maicol07-server";
  isPersonal = hostname == "maicol07-pc" || hostname == "maicol07-galaxy" || hostname == "MAICOL-MAC";
  isLinuxPersonal = isPersonal && hostname != "MAICOL-MAC";
in
{
  home.packages =
    (import ./packages/common.nix { inherit pkgs; })
    ++ lib.optionals isServer (import ./packages/server.nix { inherit pkgs; })
    ++ lib.optionals isPersonal (import ./packages/personal.nix { inherit pkgs; })
    ++ lib.optionals isLinuxPersonal (import ./packages/linux.nix { inherit pkgs; });
}
