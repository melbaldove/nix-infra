{ config, pkgs, ... }:

{
  services.loki = {
    enable = true;
    configuration = {
      server = {
        http_listen_port = 3100;
        http_listen_address = "0.0.0.0";  # Listen on all interfaces to accept connections from both VPN networks
      };
      
      auth_enabled = false;
      
      limits_config = {
        allow_structured_metadata = true; # Enable with TSDB backend
        retention_period = "744h"; # 31 days
        reject_old_samples = true;
        reject_old_samples_max_age = "72h"; # 3 days
      };
      
      ingester = {
        lifecycler = {
          address = "10.0.0.1";
          ring = {
            kvstore = {
              store = "inmemory";
            };
            replication_factor = 1;
          };
          final_sleep = "0s";
        };
        chunk_idle_period = "5m";    # Flush after 5 minutes idle
        max_chunk_age = "1h";        # Force flush after 1 hour  
        chunk_retain_period = "30s"; # Retain for queries
      };
      
      schema_config = {
        configs = [
          {
            store = "tsdb";
            object_store = "filesystem";
            schema = "v13";
            index = {
              prefix = "tsdb_index_";
              period = "24h";
            };
          }
        ];
      };
      
      storage_config = {
        tsdb_shipper = {
          active_index_directory = "/var/lib/loki/tsdb";
          cache_location = "/var/lib/loki/tsdb-cache";
        };
        filesystem = {
          directory = "/var/lib/loki/chunks";
        };
      };
      
      compactor = {
        working_directory = "/var/lib/loki/compactor";
      };
    };
  };
  
  # Ensure Loki data directories exist with correct ownership
  # Without this, Loki can't write to /var/lib/loki and data goes to tmpfs
  systemd.tmpfiles.rules = [
    "d /var/lib/loki 0755 loki loki -"
    "d /var/lib/loki/chunks 0755 loki loki -"
    "d /var/lib/loki/tsdb 0755 loki loki -"
    "d /var/lib/loki/tsdb-cache 0755 loki loki -"
    "d /var/lib/loki/compactor 0755 loki loki -"
  ];

  # Firewall configuration - allow Loki port on VPN interfaces
  networking.firewall.interfaces.wg-personal.allowedTCPPorts = [ 3100 ];
  networking.firewall.interfaces.wg-startup.allowedTCPPorts = [ 3100 ];
}