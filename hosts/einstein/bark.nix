{ pkgs, ... }:

let
  port = 18200;
in
{
  systemd.services.bark-server = {
    description = "Bark push relay";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.bark-server}/bin/bark-server --addr 0.0.0.0:${toString port} --data /var/lib/bark";
      DynamicUser = true;
      StateDirectory = "bark";
      Restart = "on-failure";
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
    };
  };

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ port ];
}
