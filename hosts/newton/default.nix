{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./nginx.nix
    ../../modules/shared/core.nix
    ../../modules/shared/ssh-keys.nix
    ../../modules/shared/promtail.nix
    ../../modules/linux/default.nix
    ../../modules/linux/agenix.nix
    ../../modules/infrastructure/restic-backup.nix
    ../../modules/shared/node-exporter.nix
    inputs.home-manager.nixosModules.home-manager
  ];

  networking.hostName = "newton";
  networking.extraHosts = ''
    172.236.148.68 shannon
    10.0.0.2 einstein
  '';

  # WireGuard VPN client configuration
  age.secrets.wireguard-newton-private.file = ../../secrets/infrastructure/wireguard-newton-private.age;

  networking.wireguard.interfaces = {
    wg0 = {
      ips = [ "10.0.1.2/24" ];
      privateKeyFile = config.age.secrets.wireguard-newton-private.path;

      peers = [
        {
          # Shannon VPN server (startup interface)
          publicKey = "VyeqpVLFr+62pyzKUI4Dq/WZXS5pZR/Ps2Yx3aNKgm0=";
          allowedIPs = [ "10.0.1.0/24" ];
          endpoint = "shannon:51821";
          persistentKeepalive = 25;
        }
      ];
    };
  };

  # Node exporter configuration
  monitoring.nodeExporter.listenAddress = "10.0.1.2";

  # cAdvisor for Docker container metrics
  services.cadvisor = {
    enable = true;
    port = 9200;
    listenAddress = "10.0.1.2";
  };

  # Allow VPN traffic to monitoring ports
  networking.firewall.interfaces.wg0.allowedTCPPorts = [ 9100 9200 9080 ];


  # Override Promtail client to use Shannon's startup network IP
  services.promtail.configuration.clients = lib.mkForce [
    {
      url = "http://10.0.1.1:3100/loki/api/v1/push";
    }
  ];

  # Newton-specific Promtail configuration for Docker logs
  services.promtail.configuration.scrape_configs = lib.mkAfter [
    {
      job_name = "docker-containers";
      docker_sd_configs = [
        {
          host = "unix:///var/run/docker.sock";
          refresh_interval = "5s";
          # Collect logs from all containers, not just those with specific labels
        }
      ];
      relabel_configs = [
        {
          source_labels = [ "__meta_docker_container_name" ];
          regex = "/(.*)";
          target_label = "container";
          replacement = "\${1}";
        }
        {
          source_labels = [ "__meta_docker_container_log_stream" ];
          target_label = "stream";
        }
        {
          source_labels = [ "__meta_docker_container_label_com_docker_compose_service" ];
          target_label = "compose_service";
        }
        {
          source_labels = [ "__meta_docker_container_label_com_docker_compose_project" ];
          target_label = "compose_project";
        }
        {
          source_labels = [ "__meta_docker_container_image" ];
          target_label = "image";
        }
      ];
      pipeline_stages = [
        {
          docker = {};
        }
        {
          timestamp = {
            source = "timestamp";
            format = "RFC3339Nano";
          };
        }
      ];
    }
  ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";

  # Mount Hetzner volume for backups
  fileSystems."/var/lib/restic-backups" = {
    device = "/dev/sdb";
    fsType = "ext4";
    options = [ "defaults" "noatime" ];
  };

  # Create backup directories with proper ownership
  systemd.tmpfiles.rules = [
    "d /var/lib/restic-backups/newton-restic 0755 root root -"
  ];


  environment.systemPackages = with pkgs; [
    inetutils
    mtr
    sysstat
    arion
    docker-compose
    bun
    google-chrome
  ];

  users.users.melbournebaldove = {
    isNormalUser = true;
    extraGroups = [ "wheel" "users" ];
  };


  # Grant promtail access to Docker socket for container log collection
  users.users.promtail.extraGroups = [ "docker" ];

  # Configure agenix secrets for backup
  age.secrets.restic-password.file = ../../secrets/infrastructure/restic-password.age;

  # Configure restic backup service
  services.restic-backup = {
    enable = true;
    repository = "/var/lib/restic-backups/newton-restic";
    passwordFile = config.age.secrets.restic-password.path;
    paths = [
      # Service volumes will be added by nextdesk-services
      "/var/lib"
    ];
  };

  # Services will be configured by nextdesk-services flake

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };
    users.melbournebaldove = import "${inputs.dotfiles}/users/melbournebaldove/core.nix";
  };

  system.stateVersion = "24.11";
}