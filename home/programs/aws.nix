{ lib, pkgs, isWsl ? false, ... }:
lib.mkIf isWsl {
  # Also deployed to %USERPROFILE%\.aws\config by windows/default.nix
  home.file.".aws/config".text = lib.generators.toINI { } {
    "sso-session trust" = {
      sso_start_url = "https://d-936783b4be.awsapps.com/start";
      sso_region = "eu-west-1";
      sso_registration_scopes = "sso:account:access";
    };
    "profile commpla-dev" = {
      sso_session = "trust";
      sso_account_id = "907383592745";
      sso_role_name = "AdministratorAccess";
      region = "eu-west-1";
    };
    "profile commpla-prod" = {
      sso_session = "trust";
      sso_account_id = "510706730724";
      sso_role_name = "AdministratorAccess";
      region = "eu-west-1";
    };
  };

  # Use Windows aws-vault so credentials live in Windows Credential Manager.
  # ponytail: resolves %LOCALAPPDATA% on every call (~0.1s), cache it if that ever matters
  home.packages = [
    (pkgs.writeShellScriptBin "aws-vault" ''
      localAppData=$(cd /mnt/c && /mnt/c/Windows/System32/cmd.exe /c 'echo %LOCALAPPDATA%' | tr -d '\r\n')
      exec "$(/sbin/wslpath -u "$localAppData")/Microsoft/WinGet/Links/aws-vault.exe" "$@"
    '')
  ];
}
