{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/shared/core.nix
    ../../modules/shared/ssh-keys.nix
    ../../modules/linux/default.nix
    ../../modules/linux/agenix.nix
    ../../modules/networking/wireguard-server.nix
    ../../modules/infrastructure/monitoring.nix
    inputs.haeru.nixosModules.haeru-observability
    inputs.home-manager.nixosModules.home-manager
  ];

  haeru.observability.promtail = {
    enable = true;
    lokiPushUrl = "http://10.0.0.1:3100/loki/api/v1/push";
    includeSystemJournalScrape = true;
    includeNginxScrapes = true;
    extraPromtailGroups = lib.optionals (lib.hasAttr "docker" config.users.groups) [ "docker" ];
  };


  networking.hostName = "shannon";
  networking.usePredictableInterfaceNames = false;
  networking.useDHCP = false; # Disable DHCP globally as we will not need it.
  # required for ssh?
  networking.interfaces.eth0.useDHCP = true;
  
  # Trust the deploy user for Nix store operations
  nix.settings.trusted-users = [ "root" "deploy" "@wheel" ];

  boot.loader.grub.enable = true;

  environment.systemPackages = with pkgs; [
    inetutils
    mtr
    sysstat
  ];

  users.users.melbournebaldove = {
    isNormalUser = true;
    extraGroups = [ "wheel" "users" ];
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };
    users.melbournebaldove = import "${inputs.dotfiles}/users/melbournebaldove/core.nix";
  };

  system.stateVersion = "24.11";
}
