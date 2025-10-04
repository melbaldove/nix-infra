{ config, lib, pkgs, inputs, ... }:

{
  imports = [
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

  networking.hostName = "einstein";
  networking.extraHosts = ''
    172.236.148.68 shannon
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
    extraGroups = [ "wheel" "users" ];
  };


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

  # Allow promtail port on VPN interface
  networking.firewall.interfaces.wg0.allowedTCPPorts = [ 9080 ];

  system.stateVersion = "24.05";
}
