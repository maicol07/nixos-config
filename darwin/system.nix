{ pkgs, username, ... }: {
  # Force Home Manager to use the macOS path, overriding the Linux one in home.nix
  home-manager.users.${username} = {
    home.homeDirectory = pkgs.lib.mkForce "/Users/${username}";
    home.sessionVariables = {
      SSH_AUTH_SOCK = "/Users/${username}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
    };
  };

  system.primaryUser = username;

  # Enable shell environments
  programs.zsh.enable = true;
  programs.fish.enable = true;
  environment.shells = [ pkgs.fish ];

  environment.systemPath = [ "/opt/homebrew/bin" ];

  # This value determines the Nix-Darwin release from which defaults are taken
  system.stateVersion = 5;
}
