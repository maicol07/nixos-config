{ pkgs, ... }: {
  fonts.packages = with pkgs; [
    cascadia-code
    googlesans-code
    nerd-fonts.fantasque-sans-mono
  ];
}
