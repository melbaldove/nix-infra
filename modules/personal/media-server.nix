{ config, lib, pkgs, ... }:

{
  # Jellyfin media server (open-source alternative to Emby/Plex)
  services.jellyfin = {
    enable = true;
    openFirewall = true;
    dataDir = "/var/lib/jellyfin";
    configDir = "/var/lib/jellyfin/config";
    cacheDir = "/var/cache/jellyfin";
    logDir = "/var/log/jellyfin";
    user = "jellyfin";
    group = "jellyfin";
  };

  # Create jellyfin user and ensure media directory permissions
  users.users.jellyfin = {
    isSystemUser = true;
    group = "jellyfin";
    extraGroups = [ "video" "audio" "users" ];
  };
  users.groups.jellyfin = {};

  # Install qBittorrent
  environment.systemPackages = with pkgs; [
    qbittorrent-nox
  ];

  # Create qbittorrent user and group
  users.users.qbittorrent = {
    isSystemUser = true;
    group = "qbittorrent";
    extraGroups = [ "users" ];
    home = "/var/lib/qbittorrent";
    createHome = true;
  };
  users.groups.qbittorrent = {};

  # qBittorrent daemon systemd service
  systemd.services.qbittorrent = {
    description = "qBittorrent daemon";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "forking";
      User = "qbittorrent";
      Group = "qbittorrent";
      ExecStart = "${pkgs.qbittorrent-nox}/bin/qbittorrent-nox --daemon --webui-port=8080 --confirm-legal-notice";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  # Ensure media mount is accessible to jellyfin and qbittorrent
  systemd.tmpfiles.rules = [
    "d /mnt/media 0755 root users -"
    "Z /mnt/media 0755 root users -"
    "d /var/lib/qbittorrent 0755 qbittorrent qbittorrent -"
    "d /var/lib/qbittorrent/Downloads 0755 qbittorrent qbittorrent -"
  ];

  # Open firewall ports for Jellyfin and qBittorrent
  networking.firewall = {
    allowedTCPPorts = [ 
      8096  # HTTP web interface
      8920  # HTTPS web interface  
      8080  # qBittorrent web interface
    ];
    allowedUDPPorts = [
      1900  # DLNA discovery
      7359  # Jellyfin autodiscovery
    ];
  };
}