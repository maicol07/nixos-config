{ pkgs, ... }:

with pkgs; [
  ###### System ######
  coreutils
  curl
  findutils
  killall
  htop

  ###### Utilities ######
  croc
  dos2unix
  dust
  duf
  fresh-editor
  fx
  grc
  httpie
  jq
  lsof
  nix-inspect
  procs
  sd
  tlrc
  tree
  unzip
  wget
  zip
  xcp
  epiphany

  ###### LSP for Fresh Editor ######
  bash-language-server
]
