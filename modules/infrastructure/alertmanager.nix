{ config, pkgs, ... }:

{
  # Create alertmanager user early in activation
  users.users.alertmanager = {
    isSystemUser = true;
    group = "alertmanager";
    description = "AlertManager daemon user";
  };
  users.groups.alertmanager = {};

  age.secrets.alertmanager-slack-nextdesk = {
    file = ../../secrets/infrastructure/alertmanager-slack-nextdesk.age;
    owner = "alertmanager";
    group = "alertmanager";
  };

  age.secrets.alertmanager-slack-haeru = {
    file = ../../secrets/infrastructure/alertmanager-slack-haeru.age;
    owner = "alertmanager";
    group = "alertmanager";
  };

  services.prometheus.alertmanager = {
    enable = true;
    port = 9093;
    listenAddress = "localhost";
    
    configuration = {
      route = {
        group_by = [ "cluster" "service" "severity" ];
        group_wait = "10s";
        group_interval = "10s";
        repeat_interval = "1h";
        receiver = "default";
        routes = [
          {
            matchers = [ ''environment="production"'' "severity=~critical|warning" ];
            receiver = "slack-haeru-prod";
          }
          {
            matchers = [ "severity=~critical|warning" ];
            receiver = "slack-haeru-dev";
          }
        ];
      };
      
      receivers = [
        {
          name = "default";
        }
        {
          name = "slack-nextdesk";
          slack_configs = [
            {
              channel = "#alerts";
              send_resolved = true;
              title = "{{ .GroupLabels.cluster }} Alert";
              text = ''
                {{ range .Alerts }}
                *{{ .Annotations.summary }}*
                {{ .Annotations.description }}
                *Labels:* {{ range .Labels.SortedPairs }}{{ .Name }}={{ .Value }} {{ end }}
                {{ end }}
              '';
              color = ''{{ if eq .Status "firing" }}danger{{ else }}good{{ end }}'';
              api_url_file = config.age.secrets.alertmanager-slack-nextdesk.path;
            }
          ];
        }
        {
          name = "slack-haeru-prod";
          slack_configs = [
            {
              channel = "#alerts";
              send_resolved = true;
              title = ":rotating_light: Production Alert";
              text = ''
                {{ range .Alerts }}
                *{{ .Annotations.summary }}*
                {{ .Annotations.description }}
                *Labels:* {{ range .Labels.SortedPairs }}{{ .Name }}={{ .Value }} {{ end }}
                {{ end }}
              '';
              color = ''{{ if eq .Status "firing" }}danger{{ else }}good{{ end }}'';
              api_url_file = config.age.secrets.alertmanager-slack-haeru.path;
            }
          ];
        }
        {
          name = "slack-haeru-dev";
          slack_configs = [
            {
              channel = "#dev-alerts";
              send_resolved = true;
              title = "Development Alert";
              text = ''
                {{ range .Alerts }}
                *{{ .Annotations.summary }}*
                {{ .Annotations.description }}
                *Labels:* {{ range .Labels.SortedPairs }}{{ .Name }}={{ .Value }} {{ end }}
                {{ end }}
              '';
              color = ''{{ if eq .Status "firing" }}danger{{ else }}good{{ end }}'';
              api_url_file = config.age.secrets.alertmanager-slack-haeru.path;
            }
          ];
        }
      ];
    };
  };
  
  networking.firewall.allowedTCPPorts = [ 9093 ];
}
