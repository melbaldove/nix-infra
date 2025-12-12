{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    inputs.disko.nixosModules.disko
    ./disko-config.nix
    ../../modules/shared/core.nix
    ../../modules/shared/ssh-keys.nix
    ../../modules/linux/default.nix
    ../../modules/linux/agenix.nix
    inputs.haeru.nixosModules.haeru-services
    inputs.haeru.nixosModules.haeru-observability
    inputs.home-manager.nixosModules.home-manager
  ];

  # Haeru production services
  services.haeru = {
    enable = true;
    environment = "production";
    domain = "api.haeru.app";
    consoleDomain = "console.haeru.app";

    # Expose metrics on VPN interface for Shannon's Prometheus to scrape
    bindings.metricsAddress = "10.0.1.3";
  };

  # Observability: ship logs to Shannon's Loki
  haeru.observability.promtail = {
    enable = true;
    lokiPushUrl = "http://10.0.1.1:3100/loki/api/v1/push";
    includeSystemJournalScrape = true;
    includeNginxScrapes = true;
  };

  haeru.observability.grafana.enable = true;

  networking.hostName = "feynman";
  networking.usePredictableInterfaceNames = false;
  networking.useDHCP = false;
  networking.interfaces.eth0.useDHCP = true;

  # Firewall: strict production lockdown
  # Public internet: only nginx (80/443)
  # VPN: SSH and metrics for Prometheus scraping
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 80 443 ]; # nginx only
    allowedUDPPorts = [ ];
    interfaces.wg-startup = {
      allowedTCPPorts = [
        22    # SSH
        9618  # Memgraph ingest worker metrics
        9619  # Memgraph consolidate worker metrics
      ];
    };
  };

  # Disable the default SSH port opening
  services.openssh.openFirewall = false;

  # Trust the deploy user for Nix store operations
  nix.settings.trusted-users = [ "root" "deploy" "@wheel" ];

  # Bootloader for Hetzner Cloud (UEFI)
  boot.loader.grub.enable = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.efiInstallAsRemovable = true;
  boot.loader.grub.device = "nodev";

  # Kernel modules for Hetzner Cloud
  boot.initrd.availableKernelModules = [ "virtio_pci" "virtio_scsi" "ahci" "sd_mod" ];

  environment.systemPackages = with pkgs; [
    inetutils
    mtr
    sysstat
  ];

  users.users.melbournebaldove = {
    isNormalUser = true;
    extraGroups = [ "wheel" "users" ];
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };
    users.melbournebaldove = import "${inputs.dotfiles}/users/melbournebaldove/core.nix";
  };

  # WireGuard client to connect back to Shannon (wg-startup network)
  age.secrets.wireguard-feynman-private.file = ../../secrets/infrastructure/wireguard-feynman-private.age;

  networking.wireguard.interfaces = {
    wg-startup = {
      ips = [ "10.0.1.3/24" ];
      privateKeyFile = config.age.secrets.wireguard-feynman-private.path;

      peers = [
        {
          # Shannon VPN server
          publicKey = "VyeqpVLFr+62pyzKUI4Dq/WZXS5pZR/Ps2Yx3aNKgm0=";
          endpoint = "172.236.148.68:51821";
          allowedIPs = [ "10.0.1.0/24" "10.0.0.0/24" ];
          persistentKeepalive = 25;
        }
      ];
    };
  };

  system.stateVersion = "24.11";
}
