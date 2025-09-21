{ config, pkgs, ... }:

{
  services.promtail = {
    enable = true;
    configuration = {
      server = {
        http_listen_port = 9080;
        grpc_listen_port = 0;
      };
      
      positions = {
        filename = "/var/lib/promtail/positions.yaml";
      };
      
      clients = [
        {
          url = "http://10.0.0.1:3100/loki/api/v1/push";
        }
      ];
      
      scrape_configs = [
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
                expression = "^(?P<remote_addr>[\\w\\.]+) - (?P<remote_user>\\S+) \\[(?P<time_local>[\\w:/]+\\s[+\\-]\\d{4})\\] \"(?P<method>\\S+) (?P<path>\\S+) (?P<protocol>\\S+)\" (?P<status>\\d{3}) (?P<body_bytes_sent>\\d+) \"(?P<http_referer>[^\"]*)\" \"(?P<http_user_agent>[^\"]*)\"";
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
                expression = "^(?P<timestamp>\\d{4}/\\d{2}/\\d{2} \\d{2}:\\d{2}:\\d{2}) \\[(?P<level>\\w+)\\] (?P<message>.*)";
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
    };
  };
  
  # Ensure promtail data directory exists
  systemd.tmpfiles.rules = [
    "d /var/lib/promtail 0755 promtail promtail -"
  ];
  
  # Grant promtail access to system logs and docker (if available)
  users.groups.promtail.members = [ "promtail" ];
  users.users.promtail.extraGroups = [ "systemd-journal" ] ++ 
    (if builtins.hasAttr "docker" config.users.groups then [ "docker" ] else []);
}