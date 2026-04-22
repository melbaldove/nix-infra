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
      listen = [{ addr = "10.0.0.2"; port = 80; }];

      # /api/* → API on :3000 (strip the /api prefix; routes mount bare).
      # proxyWebsockets handles /api/ws/events upgrade too.
      locations."/api/" = {
        proxyPass = "http://127.0.0.1:3000/";
        proxyWebsockets = true;
      };

      # Everything else → static web bundle served on :8080.
      locations."/" = {
        proxyPass = "http://127.0.0.1:8080";
        proxyWebsockets = true;
      };
    };
  };
}
