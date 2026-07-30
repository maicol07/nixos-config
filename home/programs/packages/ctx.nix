{ pkgs }:

pkgs.buildGoModule {
  pname = "ctx";
  version = "0.1.0";

  src = pkgs.fetchFromGitHub {
    owner = "vlebo";
    repo = "ctx";
    rev = "a6941b6acc0703574e2df99cf06b76e4ebbfca72";
    hash = "sha256-ekggrJX0DTSlslxSZgX/Jv2b21yy4i5ax/ToVykXuPE=";
  };

  vendorHash = "sha256-BPiT+UL74j31g5ftjVpJt0P4lTfdlPViTloKKjMZvcM=";
  subPackages = [ "cmd/ctx" ];

  meta = with pkgs.lib; {
    description = "Multi-environment context switcher for DevOps";
    homepage = "https://github.com/vlebo/ctx";
    mainProgram = "ctx";
  };
}
