{ pkgs }:

pkgs.buildGoModule {
  pname = "ctx";
  version = "0.1.16";

  src = pkgs.fetchFromGitHub {
    owner = "vlebo";
    repo = "ctx";
    rev = "a7cd9a2a4b5a5ac2a80243784d17751dfeddec37";
    hash = "sha256-IRRguXDG18N5k7GnALax4Srar9/x+HZgqH+sBFc4g2w=";
  };

  vendorHash = "sha256-BPiT+UL74j31g5ftjVpJt0P4lTfdlPViTloKKjMZvcM=";
  subPackages = [ "cmd/ctx" ];

  meta = with pkgs.lib; {
    description = "Multi-environment context switcher for DevOps";
    homepage = "https://github.com/vlebo/ctx";
    mainProgram = "ctx";
  };
}
