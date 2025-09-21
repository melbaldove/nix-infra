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


  # Add ntfs-3g for NTFS support
  environment.systemPackages = with pkgs; [
    ntfs3g
  ];


  # Configure as remote builder
  nix.settings = {
    trusted-users = [ "root" "melbournebaldove" ];
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