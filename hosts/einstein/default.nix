{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    inputs.haeru.nixosModules.amplify
    ./hardware-configuration.nix
    ../../modules/shared/core.nix
    ../../modules/shared/ssh-keys.nix
    ../../modules/shared/promtail.nix
    ../../modules/linux/default.nix
    ../../modules/linux/agenix.nix
    ../../modules/personal/media-server.nix
    ../../modules/networking/wireguard-gateway.nix
    ../../modules/shared/node-exporter.nix
    ../../modules/infrastructure/github-runner.nix
    inputs.home-manager.nixosModules.home-manager
  ];

  # Amplify distribution engine
  services.amplify.enable = true;

  networking.hostName = "einstein";
  networking.extraHosts = ''
    10.0.0.1 shannon  # VPN IP for SSH deployment
    10.0.1.3 feynman
    157.180.91.120 newton
  '';

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Mount /dev/sda1 to /mnt/media (NTFS)
  fileSystems."/mnt/media" = {
    device = "/dev/sda1";
    fsType = "ntfs-3g";
    options = [ "defaults" "rw" "uid=1000" "gid=100" "umask=002" "nofail" ];
  };

  users.users.melbournebaldove = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [ "wheel" "users" ];
  };

  programs.zsh.enable = true;

  # Allow github-runner to run nixos-rebuild with sudo for automated deployments
  security.sudo.extraRules = [{
    users = [ "github-runner" ];
    commands = [{
      command = "/run/current-system/sw/bin/nixos-rebuild";
      options = [ "NOPASSWD" ];
    }];
  }];

  # Override github-runner service to allow privilege escalation via sudo
  systemd.services.github-runner-haeru-runner.serviceConfig.NoNewPrivileges = lib.mkForce false;

  age.secrets.nix-serve-cache.file = ../../secrets/infrastructure/nix-serve-cache.age;

  services.nix-serve = {
    enable = true;
    package = pkgs.nix-serve-ng;
    bindAddress = "10.0.0.2";
    port = 8081;
    openFirewall = true;
    secretKeyFile = config.age.secrets.nix-serve-cache.path;
  };


  # Add ntfs-3g for NTFS support
  environment.systemPackages = with pkgs; [
    ntfs3g
  ];


  # Configure as remote builder
  nix.settings = {
    trusted-users = [ "root" "melbournebaldove" ];
    substituters = lib.mkAfter [ "http://10.0.0.2:8081" ];
    trusted-public-keys = lib.mkAfter [ "haeru-cache:m31dOHpFNZLXcN/Ts6luYMhDFvpqPjPBOkzioup9Q24=" ];
  };


  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    extraSpecialArgs = { inherit inputs; };
    users.melbournebaldove = {
      imports = [
        "${inputs.dotfiles}/users/melbournebaldove/core.nix"
        "${inputs.dotfiles}/users/melbournebaldove/claude.nix"
        "${inputs.dotfiles}/users/melbournebaldove/dev.nix"
      ];
    };
  };

  monitoring.nodeExporter.listenAddress = "10.0.0.2";

  # Allow promtail and openclaw gateway on VPN interface only
  networking.firewall.interfaces.wg0.allowedTCPPorts = [ 9080 18789 ];

  # NAT VPN traffic to openclaw gateway on loopback
  boot.kernel.sysctl."net.ipv4.conf.wg0.route_localnet" = 1;
  networking.nat.enable = true;
  networking.firewall.extraCommands = ''
    iptables -t nat -A PREROUTING -i wg0 -p tcp --dport 18789 -j DNAT --to-destination 127.0.0.1:18789
  '';
  networking.firewall.extraStopCommands = ''
    iptables -t nat -D PREROUTING -i wg0 -p tcp --dport 18789 -j DNAT --to-destination 127.0.0.1:18789 2>/dev/null || true
  '';

  system.stateVersion = "24.05";
}
