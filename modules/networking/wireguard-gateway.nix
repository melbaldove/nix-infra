{ config, lib, pkgs, ... }:

{
  # Declare the encrypted secret
  age.secrets.wireguard-einstein-private.file = ../../secrets/infrastructure/wireguard-einstein-private.age;

  networking.firewall = {
    trustedInterfaces = [ "wg0" ];
  };

  networking.nat = {
    enable = true;
    externalInterface = "enp4s0";
    internalInterfaces = [ "wg0" ];
  };

  networking.wireguard.interfaces = {
    # Personal VPN network
    wg0 = {
      ips = [ "10.0.0.2/24" ];

      postSetup = ''
        # Route home network traffic through this gateway
        ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s 192.168.50.0/24 -o wg0 -j MASQUERADE
        ${pkgs.iptables}/bin/iptables -A FORWARD -i wg0 -o enp4s0 -j ACCEPT
        ${pkgs.iptables}/bin/iptables -A FORWARD -i enp4s0 -o wg0 -j ACCEPT
      '';

      postShutdown = ''
        ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s 192.168.50.0/24 -o wg0 -j MASQUERADE
        ${pkgs.iptables}/bin/iptables -D FORWARD -i wg0 -o enp4s0 -j ACCEPT
        ${pkgs.iptables}/bin/iptables -D FORWARD -i enp4s0 -o wg0 -j ACCEPT
      '';

      privateKeyFile = config.age.secrets.wireguard-einstein-private.path;

      peers = [
        {
          # Shannon VPN server
          publicKey = "8jFBCynKH6dwA/T/duyIg7n2GSaC1gBsjJREYjWdyU4=";
          allowedIPs = [ "10.0.0.0/24" ];
          endpoint = "shannon:51820";
          persistentKeepalive = 25;
        }
      ];
    };

    # Startup VPN network
    wg-startup = {
      ips = [ "10.0.1.4/24" ];

      privateKeyFile = config.age.secrets.wireguard-einstein-private.path;

      peers = [
        {
          # Shannon VPN server (startup network)
          publicKey = "VyeqpVLFr+62pyzKUI4Dq/WZXS5pZR/Ps2Yx3aNKgm0=";
          allowedIPs = [ "10.0.1.0/24" ];
          endpoint = "shannon:51821";
          persistentKeepalive = 25;
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