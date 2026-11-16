{ lib, pkgs, isWsl ? false, ... }:
let
  accounts = {
    commpla-dev = "907383592745";
    commpla-prod = "510706730724";
  };

  ssoProfiles = lib.mapAttrs' (name: id: lib.nameValuePair "profile ${name}-sso" {
    sso_session = "trust";
    sso_account_id = id;
    sso_role_name = "AdministratorAccess";
    region = "eu-west-1";
  }) accounts;

  vaultProfiles = lib.mapAttrs' (name: _: lib.nameValuePair "profile ${name}" {
    region = "eu-west-1";
    credential_process = "aws-vault export --format=json ${name}-sso";
  }) accounts;
in lib.mkIf isWsl {
  # Also deployed to %USERPROFILE%\.aws\config by windows/default.nix
  home.file.".aws/config".text = lib.generators.toINI { } ({
    "sso-session trust" = {
      sso_start_url = "https://d-936783b4be.awsapps.com/start";
      sso_region = "eu-west-1";
      sso_registration_scopes = "sso:account:access";
    };
  } // ssoProfiles // vaultProfiles);

  # Use Windows aws-vault so credentials live in Windows Credential Manager.
  # ponytail: resolves %LOCALAPPDATA% on every call (~0.1s), cache it if that ever matters
  home.packages = [
    (pkgs.writeShellScriptBin "aws-vault" ''
      localAppData=$(cd /mnt/c && /mnt/c/Windows/System32/cmd.exe /c 'echo %LOCALAPPDATA%' | tr -d '\r\n')
      exec "$(/sbin/wslpath -u "$localAppData")/Microsoft/WinGet/Links/aws-vault.exe" "$@"
    '')
  ];
}
