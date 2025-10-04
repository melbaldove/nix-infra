{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/shared/core.nix
    ../../modules/shared/ssh-keys.nix
    ../../modules/linux/default.nix
    ../../modules/linux/agenix.nix
    ../../modules/networking/wireguard-server.nix
    ../../modules/infrastructure/monitoring.nix
    inputs.haeru.nixosModules.haeru-observability
    inputs.home-manager.nixosModules.home-manager
  ];

  haeru.observability.promtail = {
    enable = true;
    lokiPushUrl = "http://10.0.0.1:3100/loki/api/v1/push";
    includeDefaultIngestionScrape = true;
    ingestionLogPaths = [ "/var/log/haeru/ingestion/*.jsonl" ];
    scrapeConfigs = [
      {
        job_name = "systemd-journal";
        journal = {
          max_age = "12h";
          labels = {
            job = "systemd-journal";
            host = config.networking.hostName;
          };
        };
        relabel_configs = [
          {
            source_labels = [ "__journal__systemd_unit" ];
            target_label = "unit";
          }
          {
            source_labels = [ "__journal_syslog_identifier" ];
            target_label = "syslog_identifier";
          }
          {
            source_labels = [ "__journal_priority" ];
            target_label = "priority";
          }
        ];
      }
      {
        job_name = "nginx-access";
        static_configs = [
          {
            targets = [ "localhost" ];
            labels = {
              job = "nginx-access";
              host = config.networking.hostName;
              __path__ = "/var/log/nginx/access.log";
            };
          }
        ];
        pipeline_stages = [
          {
            regex = {
              expression = ''^(?P<remote_addr>[\w\.]+) - (?P<remote_user>\S+) \[(?P<time_local>[\w:/]+\s[+\-]\d{4})\] "(?P<method>\S+) (?P<path>\S+) (?P<protocol>\S+)" (?P<status>\d{3}) (?P<body_bytes_sent>\d+) "(?P<http_referer>[^"]*)" "(?P<http_user_agent>[^"]*)"'';
            };
          }
          {
            labels = {
              method = "";
              status = "";
              path = "";
            };
          }
        ];
      }
      {
        job_name = "nginx-error";
        static_configs = [
          {
            targets = [ "localhost" ];
            labels = {
              job = "nginx-error";
              host = config.networking.hostName;
              __path__ = "/var/log/nginx/error.log";
            };
          }
        ];
        pipeline_stages = [
          {
            regex = {
              expression = "^(?P<timestamp>\d{4}/\d{2}/\d{2} \d{2}:\d{2}:\d{2}) \[(?P<level>\w+)\] (?P<message>.*)";
            };
          }
          {
            labels = {
              level = "";
            };
          }
        ];
      }
    ];
    extraPromtailGroups = [ "nginx" ]
      ++ lib.optionals (lib.hasAttr "docker" config.users.groups) [ "docker" ];
  };


  networking.hostName = "shannon";
  networking.usePredictableInterfaceNames = false;
  networking.useDHCP = false; # Disable DHCP globally as we will not need it.
  # required for ssh?
  networking.interfaces.eth0.useDHCP = true;
  
  # Trust the deploy user for Nix store operations
  nix.settings.trusted-users = [ "root" "deploy" "@wheel" ];

  boot.loader.grub.enable = true;

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

  system.stateVersion = "24.11";
}
