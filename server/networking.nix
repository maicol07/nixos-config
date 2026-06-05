{ hostname, username, lib, ... }: {
  networking = {
    hostName = hostname;
    networkmanager.enable = true;
    interfaces.enp0s25.wakeOnLan.enable = true;
    firewall.enable = false;
  };

  services.openssh = {
    enable = true;
    openFirewall = false;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      X11Forwarding = true;
      AllowTcpForwarding = "yes";
      AllowAgentForwarding = "yes";
      UseDns = false;
      Subsystem = "sftp /run/current-system/sw/lib/ssh/sftp-server";
    };
  };

  users.users.${username}.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIujyUjvzrsTC7MzvFJn5RK2pf4UyXUQQAoTlrjw+6i9"
  ];
}
