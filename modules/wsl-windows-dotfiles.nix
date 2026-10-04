{
  config,
  pkgs,
  self,
  hostname,
  username,
  utils,
  ...
}: let
  homeManagerService = "home-manager-${utils.escapeSystemdPath username}.service";
  bundle = self.packages.${pkgs.stdenv.hostPlatform.system}."windows-dotfiles-${hostname}";
in {
  assertions = [
    {
      assertion = config.wsl.enable && config.wsl.wslConf.interop.enabled && config.wsl.wslConf.automount.enabled;
      message = "Automatic Windows dotfile deployment requires WSL interop and automounted Windows drives.";
    }
  ];

  # NixOS stops and starts this target on every switch, including unchanged ones.
  systemd.targets.windows-dotfiles = {
    description = "Apply Windows user dotfiles";
    wantedBy = ["multi-user.target"];
    unitConfig.X-StopOnReconfiguration = true;
  };

  systemd.services.windows-dotfiles = {
    description = "Deploy the current generation's Windows user dotfiles";
    requiredBy = ["windows-dotfiles.target"];
    before = ["windows-dotfiles.target"];
    requires = [homeManagerService];
    after = [homeManagerService];
    environment = {
      PYTHONDONTWRITEBYTECODE = "1";
      SYS_POWERSHELL = "${config.wsl.wslConf.automount.root}/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe";
    };
    serviceConfig = {
      Type = "oneshot";
      User = username;
      ExecStart = "${pkgs.python3}/bin/python3 ${../scripts/windows_deploy.py} ${bundle}";
    };
  };
}
