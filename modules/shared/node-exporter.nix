{ config, pkgs, lib, ... }:

{
  options.monitoring.nodeExporter.listenAddress = lib.mkOption {
    type = lib.types.str;
    description = "IP address for node exporter to bind to";
  };

  config = {
    services.prometheus.exporters.node = {
      enable = true;
      port = 9100;
      listenAddress = config.monitoring.nodeExporter.listenAddress;
      enabledCollectors = [ "textfile" ];
      extraFlags = [ "--collector.textfile.directory=/var/lib/node_exporter/textfile_collector" ];
    };
    
    # Create textfile collector directory
    systemd.tmpfiles.rules = [
      "d /var/lib/node_exporter/textfile_collector 0755 root root -"
    ];
  };
}