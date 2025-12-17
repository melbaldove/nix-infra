{ config, pkgs, lib, inputs, ... }:

let
  haeruPrometheusJobs = lib.concatMap (path: import path) [
    (inputs.haeru.outPath + "/observability/prometheus/jobs/platform-api.nix")
    (inputs.haeru.outPath + "/observability/prometheus/jobs/brain-backend.nix")
    (inputs.haeru.outPath + "/observability/prometheus/jobs/worker-metrics.nix")
  ];

  yamlFormat = pkgs.formats.yaml {};
  haeruPrometheusAlertFiles = [
    (yamlFormat.generate "haeru-brain-alerts.yml" (import (inputs.haeru.outPath + "/observability/prometheus/alerts/brain.nix")))
    (yamlFormat.generate "haeru-platform-alerts.yml" (import (inputs.haeru.outPath + "/observability/prometheus/alerts/platform.nix")))
    (yamlFormat.generate "haeru-ingestion-alerts.yml" (import (inputs.haeru.outPath + "/observability/prometheus/alerts/ingestion.nix")))
    (yamlFormat.generate "haeru-rabbitmq-alerts.yml" (import (inputs.haeru.outPath + "/observability/prometheus/alerts/rabbitmq.nix")))
  ];

in
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
    ] ++ haeruPrometheusAlertFiles;
    
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
          ];
        }];
      }
      {
        job_name = "blackbox-exporter";
        static_configs = [{
          targets = [ "localhost:9115" ];
        }];
      }
    ] ++ haeruPrometheusJobs;
    
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

  systemd.services.grafana.serviceConfig.EnvironmentFile = [
    config.age.secrets."haeru-grafana-db-password".path
    config.age.secrets."haeru-grafana-db-password-prod".path
  ];

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
