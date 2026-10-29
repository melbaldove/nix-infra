{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/shared/core.nix
    ../../modules/shared/ssh-keys.nix
    ../../modules/linux/default.nix
    ../../modules/linux/agenix.nix
    ../../modules/personal/media-server.nix
    ./nginx.nix
    ./bark.nix
    inputs.home-manager.nixosModules.home-manager
  ];

  services.tailscale = {
    enable = true;
    openFirewall = true;
  };

  networking.hostName = "einstein";
  networking.extraHosts = ''
    157.180.91.120 newton
  '';

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Mount /dev/sda1 to /mnt/media (NTFS)
  fileSystems."/mnt/media" = {
    device = "/dev/sda1";
    fsType = "ntfs-3g";
    options = [ "defaults" "rw" "uid=1000" "gid=100" "umask=002" "nofail" ];
  };

  users.users.melbournebaldove = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [ "wheel" "users" "docker" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIKzco47R/VfSeaEfMQu144S0iIOlFWmuTVLkc+J4dkx melbournebaldove@eisenhower"
    ];
  };

  programs.zsh.enable = true;

  virtualisation.docker.enable = true;

  # Enable nix-ld for dynamically linked binaries (Playwright Chromium)
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    glib
    nss
    nspr
    atk
    at-spi2-atk
    cups
    dbus
    expat
    libxkbcommon
    xorg.libX11
    xorg.libXcomposite
    xorg.libXdamage
    xorg.libXext
    xorg.libXfixes
    xorg.libXrandr
    xorg.libxcb
    libgbm
    cairo
    pango
    alsa-lib
    at-spi2-core
    systemdLibs
  ];

  age.secrets.nix-serve-cache.file = ../../secrets/infrastructure/nix-serve-cache.age;

  services.nix-serve = {
    enable = true;
    package = pkgs.nix-serve-ng;
    bindAddress = "127.0.0.1";
    port = 8081;
    openFirewall = false;
    secretKeyFile = config.age.secrets.nix-serve-cache.path;
  };


  # Add ntfs-3g for NTFS support
  environment.systemPackages = with pkgs; [
    ntfs3g
    chromium
  ];


  # Configure as remote builder
  nix.settings = {
    trusted-users = [ "root" "melbournebaldove" ];
    substituters = lib.mkAfter [ "http://127.0.0.1:8081" ];
    trusted-public-keys = lib.mkAfter [ "haeru-cache:m31dOHpFNZLXcN/Ts6luYMhDFvpqPjPBOkzioup9Q24=" ];
  };


  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    extraSpecialArgs = { inherit inputs; };
    users.melbournebaldove = {
      imports = [
        "${inputs.dotfiles}/users/melbournebaldove/core.nix"
        "${inputs.dotfiles}/users/melbournebaldove/claude.nix"
        "${inputs.dotfiles}/users/melbournebaldove/dev.nix"
      ];
    };
  };

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 18789 3773 18100 ];

  boot.kernel.sysctl."net.ipv4.conf.tailscale0.route_localnet" = 1;
  networking.firewall.extraCommands = ''
    iptables -t nat -A PREROUTING -i tailscale0 -p tcp --dport 18789 -j DNAT --to-destination 127.0.0.1:18789
    iptables -t nat -A PREROUTING -i tailscale0 -d 100.74.255.22 -p tcp --dport 3773 -j DNAT --to-destination 127.0.0.1:3773
  '';
  networking.firewall.extraStopCommands = ''
    iptables -t nat -D PREROUTING -i tailscale0 -p tcp --dport 18789 -j DNAT --to-destination 127.0.0.1:18789 2>/dev/null || true
    iptables -t nat -D PREROUTING -i tailscale0 -d 100.74.255.22 -p tcp --dport 3773 -j DNAT --to-destination 127.0.0.1:3773 2>/dev/null || true
  '';

  # NVIDIA RTX 2070 SUPER (TU104) - enables NVENC hardware video encoding.
  # Proprietary driver rather than `open`: better-proven NVENC support on Turing.
  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];  # loads the module; does not enable X
  hardware.nvidia = {
    modesetting.enable = true;
    open = false;
    nvidiaSettings = false;      # headless host, no GUI
    powerManagement.enable = false;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  system.stateVersion = "24.05";
}
