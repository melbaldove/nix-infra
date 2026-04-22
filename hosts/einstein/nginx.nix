{ config, lib, pkgs, ... }:

{
  services.nginx = {
    enable = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
    recommendedProxySettings = true;

    logError = "stderr";
    commonHttpConfig = ''
      access_log syslog:server=unix:/dev/log,tag=nginx_access combined;
    '';

    virtualHosts.blather = {
      default = true;
      listen = [{ addr = "10.0.0.2"; port = 18100; }];

      # /api/* → API on :3000 (strip the /api prefix; routes mount bare).
      # proxyWebsockets handles /api/ws/events upgrade too.
      locations."/api/" = {
        proxyPass = "http://127.0.0.1:3000/";
        proxyWebsockets = true;
      };

      # Everything else → static web bundle served on :18101.
      # (qbittorrent owns *:8080; we avoid the collision by binding the
      # static server to a dedicated loopback port and routing via nginx.)
      locations."/" = {
        proxyPass = "http://127.0.0.1:18101";
        proxyWebsockets = true;
      };
    };
  };
}
