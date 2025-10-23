{ pkgs, lib, isWsl ? false, ...}: {
    programs.git = {
      enable = true;
      package = pkgs.git;

      lfs.enable = true;
      
      signing.format = "ssh";
      signing.key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINsTYhlq5t/r3eawNERL09+PltjDh+fLQO1gE5TgWGmr";
      signing.signer = lib.mkIf isWsl "/mnt/c/Users/Maicol/AppData/Local/Microsoft/WindowsApps/op-ssh-sign-wsl.exe";

      includes = [
        {
          condition = "hasconfig:remote.*.url:git@gitlab.trust-itservices.com:*/**";
          contents = {
            user.email = "m.battistini@trust-itservices.com";
            user.signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIujyUjvzrsTC7MzvFJn5RK2pf4UyXUQQAoTlrjw+6i9";
          };
        }
      ];

      settings = {
        core = {
          autocrlf = "input";
          eol = "lf";
        } // lib.optionalAttrs isWsl { sshCommand = "/mnt/c/Windows/System32/OpenSSH/ssh.exe"; };

        init.defaultBranch = "main";

        pull.rebase = false;

        commit.gpgSign = true;

        merge = {
          conflictstyle = "diff3";
        };
        diff = {
          colorMoved = "default";
        };
        user = {
          email = "maicolbattistini@live.it";
          name = "Maicol Battistini";
        };
      };
    };

    programs.delta = {
      enable = true;
      enableGitIntegration = true;
    };
}