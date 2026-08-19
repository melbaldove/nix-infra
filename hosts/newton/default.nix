{ config, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./nginx.nix
    ../../modules/shared/core.nix
    ../../modules/shared/ssh-keys.nix
    ../../modules/linux/default.nix
    ../../modules/infrastructure/restic-backup.nix
    inputs.home-manager.nixosModules.home-manager
  ];

  networking.hostName = "newton";

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";

  # Mount Hetzner volume for backups
  fileSystems."/var/lib/restic-backups" = {
    device = "/dev/sdb";
    fsType = "ext4";
    options = [ "defaults" "noatime" ];
  };

  # Create backup directories with proper ownership
  systemd.tmpfiles.rules = [
    "d /var/lib/restic-backups/newton-restic 0755 root root -"
  ];


  environment.systemPackages = with pkgs; [
    inetutils
    mtr
    sysstat
    arion
    docker-compose
    bun
    google-chrome
  ];

  users.users.melbournebaldove = {
    isNormalUser = true;
    extraGroups = [ "wheel" "users" ];
  };


  # Configure agenix secrets for backup
  age.secrets.restic-password.file = ../../secrets/infrastructure/restic-password.age;

  # Configure restic backup service
  services.restic-backup = {
    enable = true;
    repository = "/var/lib/restic-backups/newton-restic";
    passwordFile = config.age.secrets.restic-password.path;
    paths = [
      "/var/lib/docker/volumes/ghost_ghost-content"
      "/var/lib/docker/volumes/ghost_db-data"
      "/var/lib/docker/volumes/twenty_db-data"
      "/var/lib/docker/volumes/twenty_server-local-data"
      "/var/lib/docker/volumes/outline_outline-data"
    ];
    exclude = [
      "/var/lib/restic-backups"  # Exclude the backup repository itself
    ];
  };

  # Services will be configured by nextdesk-services flake

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };
    users.melbournebaldove = import "${inputs.dotfiles}/users/melbournebaldove/core.nix";
  };

  system.stateVersion = "24.11";
}
