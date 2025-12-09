{ config, lib, pkgs, ... }:

{
  # Declare the encrypted secrets
  age.secrets.wireguard-shannon-private.file = ../../secrets/infrastructure/wireguard-shannon-private.age;
  age.secrets.wireguard-shannon-startup-private.file = ../../secrets/infrastructure/wireguard-shannon-startup-private.age;

  networking.firewall = {
    allowedUDPPorts = [ 51820 51821 ];
    trustedInterfaces = [ "wg-personal" "wg-startup" ];
  };

  networking.nat = {
    enable = true;
    externalInterface = "eth0";
    internalInterfaces = [ "wg-personal" "wg-startup" ];
  };

  networking.wireguard.interfaces = {
    # Personal VPN network
    wg-personal = {
      ips = [ "10.0.0.1/24" ];
      listenPort = 51820;

      postSetup = ''
        ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s 10.0.0.0/24 -o eth0 -j MASQUERADE
      '';

      postShutdown = ''
        ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s 10.0.0.0/24 -o eth0 -j MASQUERADE
      '';

      privateKeyFile = config.age.secrets.wireguard-shannon-private.path;

      peers = [
        {
          # Einstein home server/gateway
          publicKey = "S9gL9Rg+/JtzcwwUOQT4fJFjm4x/ONrGwzdjeH85jHc=";
          allowedIPs = [ "10.0.0.2/32" "192.168.50.0/24" ];
        }
        {
          # Turing client
          publicKey = "w/iizjwjWD6c3zmGYcCL0/ThHCW0odzEVbiq2FRQdBg=";
          allowedIPs = [ "10.0.0.3/32" ];
        }
        {
          # Phone client
          publicKey = "gm+26mzkPBb5AYomVDeJJddy2b00Ymv58f5H4icYgyY=";
          allowedIPs = [ "10.0.0.4/32" ];
        }
        {
          # Jena client
          publicKey = "nSHY68JYRznk8ShbpFg66Ys1g6PwaYwXD74CvbBxwlE=";
          allowedIPs = [ "10.0.0.5/32" ];
        }
        {
          # Lemuel client
          publicKey = "cBtB+KwlYjquVcDupGZAAuU0h0IViuOLtigOHVdNLXA=";
          allowedIPs = [ "10.0.0.6/32" ];
        }
      ];
    };

    # Startup VPN network
    wg-startup = {
      ips = [ "10.0.1.1/24" ];
      listenPort = 51821;

      postSetup = ''
        ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s 10.0.1.0/24 -o eth0 -j MASQUERADE
      '';

      postShutdown = ''
        ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s 10.0.1.0/24 -o eth0 -j MASQUERADE
      '';

      privateKeyFile = config.age.secrets.wireguard-shannon-startup-private.path;

      peers = [
        {
          # Newton startup server
          publicKey = "0bukNqCr3lUH0OyH4uNvYUC/JfxfuEMDpAN49/YHWgQ=";
          allowedIPs = [ "10.0.1.2/32" ];
        }
        {
          # Feynman haeru production server
          publicKey = "zDdaCFAfwPsb3r1rWu8pSmSrWFKqXRL4ll3WcZad7Fg=";
          allowedIPs = [ "10.0.1.3/32" ];
        }
      ];
    };
  };

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  environment.systemPackages = with pkgs; [
    wireguard-tools
  ];
}