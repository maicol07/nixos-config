{ pkgs, ... }: with pkgs; [
  ###### System ######
  coreutils
  curl
  findutils
  killall
  htop

  ###### Utilities ######
  antigravity-cli
  croc
  dos2unix
  dust
  duf
  fresh-editor
  fx
  git-filter-repo
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

  ###### LSP for Fresh Editor ######
  bash-language-server
]
