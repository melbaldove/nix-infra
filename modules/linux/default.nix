{ pkgs, ... }:
{

  # Set time zone
  time.timeZone = "UTC";

  # Select internationalisation properties
  i18n.defaultLocale = "en_US.UTF-8";

  # Configure sudo
  security.sudo.wheelNeedsPassword = false;

  # Enable SSH for Linux systems
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # Enable fail2ban for SSH protection
  services.fail2ban = {
    enable = true;
    maxretry = 3;
    bantime = "7d";
    ignoreIP = [
      "127.0.0.1/8"
      "10.0.0.0/24"     # Personal VPN network
      "10.0.1.0/24"     # Startup VPN network
      "192.168.50.0/24" # Local network
    ];
    jails = {
      sshd.settings = {
        enabled = true;
        filter = "sshd";
        maxretry = 3;
        findtime = "10m";
        bantime = "7d";
      };
    };
  };

  # Open SSH port in firewall
  networking.firewall.allowedTCPPorts = [ 22 ];

  # Linux-specific packages
  environment.systemPackages = with pkgs; [
    wget
    curl
    git
    htop
    tmux
  ];
}
