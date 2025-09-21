{ config, pkgs, ... }:

{
  imports = [
    ./loki.nix
    ./alertmanager.nix
  ];

  services.prometheus = {
    enable = true;
    port = 9090;
    listenAddress = "localhost";
    retentionTime = "30d";
    
    ruleFiles = [
      (pkgs.writeText "restic-alerts.yml" ''
        groups:
          - name: restic.rules
            rules:
              - alert: ResticBackupFailed
                expr: restic_backup_success == 0
                for: 0m
                labels:
                  severity: critical
                annotations:
                  summary: "Restic backup failed"
                  description: "Restic backup failed for repository {{ $labels.repository }}"
              
              - alert: ResticBackupStale
                expr: time() - restic_backup_timestamp_seconds > 86400 * 2
                for: 0m
                labels:
                  severity: warning
                annotations:
                  summary: "Restic backup is stale"
                  description: "Restic backup for {{ $labels.repository }} hasn't run in over 2 days"
              
              - alert: ResticBackupLong
                expr: restic_backup_duration_seconds > 3600
                for: 0m
                labels:
                  severity: warning
                annotations:
                  summary: "Restic backup taking too long"
                  description: "Restic backup for {{ $labels.repository }} took {{ $value | humanizeDuration }}s to complete (>1h threshold)"
      '')
      ./alert-rules/service-alerts.yml
      ./alert-rules/infrastructure-alerts.yml
      ./alert-rules/container-alerts.yml
    ];
    
    scrapeConfigs = [
      {
        job_name = "personal";
        static_configs = [{
          targets = [ 
            "127.0.0.1:9100"      # shannon itself
            "10.0.0.2:9100"       # einstein
          ];
        }];
      }
      {
        job_name = "startup";
        static_configs = [{
          targets = [ "10.0.1.2:9100" ]; # newton
        }];
      }
      {
        job_name = "cadvisor";
        static_configs = [{
          targets = [ "10.0.1.2:9200" ]; # newton cadvisor
        }];
      }
      {
        job_name = "loki";
        static_configs = [{
          targets = [ "localhost:3100" ]; # loki itself
        }];
      }
      {
        job_name = "promtail";
        static_configs = [{
          targets = [
            "localhost:9080"      # shannon promtail
            "10.0.0.2:9080"       # einstein promtail
            "10.0.1.2:9080"       # newton promtail
          ];
        }];
      }
      {
        job_name = "blackbox-exporter";
        static_configs = [{
          targets = [ "localhost:9115" ];
        }];
      }
      {
        job_name = "blackbox-http";
        static_configs = [{
          targets = [
            "https://crm.workwithnextdesk.com"
            "https://cms.workwithnextdesk.com"
            "https://wiki.workwithnextdesk.com"
            "https://n8n.workwithnextdesk.com"
          ];
        }];
        metrics_path = "/probe";
        params = {
          module = [ "http_2xx" ];
        };
        relabel_configs = [
          {
            source_labels = [ "__address__" ];
            target_label = "__param_target";
          }
          {
            source_labels = [ "__param_target" ];
            target_label = "instance";
          }
          {
            target_label = "__address__";
            replacement = "localhost:9115";
          }
        ];
      }
    ];
    
    alertmanagers = [
      {
        static_configs = [{
          targets = [ "localhost:9093" ];
        }];
      }
    ];
  };

  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "10.0.0.1";
        http_port = 3000;
      };
      security = {
        admin_user = "admin";
        admin_password = "admin";
      };
    };
    provision = {
      enable = true;
      datasources.settings = {
        apiVersion = 1;
        datasources = [
          {
            name = "Prometheus";
            type = "prometheus";
            url = "http://localhost:9090";
            isDefault = true;
            jsonData = {
              timeInterval = "5s";
            };
          }
          {
            name = "Loki";
            type = "loki";
            url = "http://localhost:3100";
            isDefault = false;
            jsonData = {
              maxLines = 1000;
            };
          }
        ];
      };
      dashboards.settings = {
        apiVersion = 1;
        providers = [
          {
            name = "default";
            orgId = 1;
            folder = "";
            type = "file";
            disableDeletion = false;
            updateIntervalSeconds = 10;
            allowUiUpdates = true;
            options = {
              path = "/var/lib/grafana/dashboards";
            };
          }
        ];
      };
    };
  };

  services.prometheus.exporters.node = {
    enable = true;
    port = 9100;
    listenAddress = "localhost";
  };

  services.prometheus.exporters.blackbox = {
    enable = true;
    port = 9115;
    listenAddress = "localhost";
    configFile = pkgs.writeText "blackbox.yml" ''
      modules:
        http_2xx:
          prober: http
          timeout: 5s
          http:
            method: GET
            valid_status_codes: [200]
            fail_if_not_ssl: true
            preferred_ip_protocol: "ip4"
        tcp_tls:
          prober: tcp
          timeout: 5s
          tcp:
            tls: true
            tls_config:
              insecure_skip_verify: false
    '';
  };

  # Symlink dashboard files for Grafana provisioning
  systemd.tmpfiles.rules = [
    "d /var/lib/grafana/dashboards 0755 grafana grafana -"
    "L+ /var/lib/grafana/dashboards/restic-backup.json - - - - ${./dashboards/restic-backup.json}"
  ];
}