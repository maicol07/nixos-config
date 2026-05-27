{ pkgs, ... }: {
  # Manage macOS packages via Homebrew
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
      upgrade = true;
    };
    taps = [
      "grishka/grishka"
    ];
    brews = [];
    casks = [
      "1password"
      "betterdisplay"
      "chrome-remote-desktop-host"
      "iterm2"
      "jetbrains-toolbox"
      "neardrop"
      "microsoft-edge"
      "parsec"
      "passepartout"
      "stats"
      "visual-studio-code"
    ];
    masApps = {
      "Xcode" = 497799835;
    };
  };
}
