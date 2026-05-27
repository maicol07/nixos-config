{ pkgs, ... }: {
  fonts.packages = with pkgs; [
    cascadia-code
    googlesans-code
  ];
}
