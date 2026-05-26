{ pkgs, ... }: [
  ###### System ######
  pkgs.coreutils
  pkgs.curl
  pkgs.findutils
  pkgs.killall
  pkgs.htop

  ###### Utilities ######
  pkgs.croc
  pkgs.dos2unix
  pkgs.dust
  pkgs.duf
  pkgs.fresh-editor
  pkgs.fx
  pkgs.grc
  pkgs.httpie
  pkgs.jq
  pkgs.lsof
  pkgs.nix-inspect
  pkgs.procs
  pkgs.sd
  pkgs.tlrc
  pkgs.tree
  pkgs.unzip
  pkgs.wget
  pkgs.zip
  pkgs.xcp

  ###### LSP for Fresh Editor ######
  pkgs.bash-language-server
]
