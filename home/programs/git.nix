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
      signing.key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINsTYhlq5t/r3eawNERL09+PltjDh+fLQO1gE5TgWGmr";

      includes = [
        {
          condition = "hasconfig:remote.*.url:git@gitlab.trust-itservices.com/**";
          contents = {
            signing.key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIujyUjvzrsTC7MzvFJn5RK2pf4UyXUQQAoTlrjw+6i9";
          };
        }
      ];

      extraConfig = {
        core = {
          autocrlf = "input";
          sshCommand = "ssh.exe";
          eol = "lf";
        };

        credential.helper = "1password"; # To us with https://github.com/ethrgeist/git-credential-1password

        init.defaultBranch = "main";

        pull.rebase = false;

        gpg.format = "ssh";

        gpg.ssh = {
           program = "/mnt/c/Users/Maicol/AppData/Local/1Password/app/8/op-ssh-sign.exe";
           allowedSignersFile = "/home/${username}/.ssh/allowed_signers";
        };

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