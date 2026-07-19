{ pkgs, lib, isServer ? false, isPersonal ? false, isDarwin ? false, ... }:
let
  isLinuxPersonal = isPersonal && !isDarwin;
in
{
  home.packages =
    (import ./packages/common.nix { inherit pkgs; })
    ++ lib.optionals isServer (import ./packages/server.nix { inherit pkgs; })
    ++ lib.optionals isPersonal (import ./packages/personal.nix { inherit pkgs lib; })
    ++ lib.optionals isLinuxPersonal (import ./packages/linux.nix { inherit pkgs; })
    ++ lib.optionals isDarwin (import ./packages/darwin.nix { inherit pkgs; });
}