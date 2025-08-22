{ pkgs, username, ...}: {
    programs.git = {
      enable = true;
      package = pkgs.git;
      delta.enable = true;
      delta.options = {
        line-numbers = true;
        side-by-side = true;
        navigate = true;
      };

      lfs.enable = true;
      
      userEmail = "maicolbattistini@live.it";
      userName = "Maicol Battistini";
      signing.format = "ssh";
      signing.key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINsTYhlq5t/r3eawNERL09+PltjDh+fLQO1gE5TgWGmr";
      signing.signer = "/mnt/c/Users/Maicol/AppData/Local/Microsoft/WindowsApps/op-ssh-sign-wsl.exe";

      includes = [
        {
          condition = "hasconfig:remote.*.url:git@gitlab.trust-itservices.com:*/**";
          contents = {
            user.email = "m.battistini@trust-itservices.com";
            user.signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIujyUjvzrsTC7MzvFJn5RK2pf4UyXUQQAoTlrjw+6i9";
          };
        }
      ];

      extraConfig = {
        core = {
          autocrlf = "input";
          sshCommand = "/mnt/c/Windows/System32/OpenSSH/ssh.exe";
          eol = "lf";
        };

        init.defaultBranch = "main";

        pull.rebase = false;

        commit.gpgSign = true;

        merge = {
          conflictstyle = "diff3";
        };
        diff = {
          colorMoved = "default";
        };
      };
    };
}