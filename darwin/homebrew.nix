{ pkgs, ... }: {
  # Manage macOS packages via Homebrew
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
      upgrade = true;
    };
    taps = [];
    brews = [];
    casks = [
      "1password"
      "betterdisplay"
      "chrome-remote-desktop-host"
      "iterm2"
      "jetbrains-toolbox"
      "microsoft-edge"
      "parsec"
      "visual-studio-code"
    ];
    masApps = {
      "Xcode" = 497799835;
    };
  };
}
