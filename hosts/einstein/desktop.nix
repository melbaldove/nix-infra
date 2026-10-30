{ pkgs, inputs, ... }:

let
  chromePkgs = import inputs.nixpkgs-chrome {
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };
in
{
  systemd.targets = {
    sleep.enable = false;
    suspend.enable = false;
    hibernate.enable = false;
    hybrid-sleep.enable = false;
  };

  services.desktopManager.plasma6.enable = true;

  services.displayManager = {
    sddm = {
      enable = true;
      wayland.enable = true;
    };
    defaultSession = "plasma";
    autoLogin = {
      enable = true;
      user = "melbournebaldove";
    };
  };

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  environment.systemPackages = [ chromePkgs.google-chrome ];

  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;
  };
  programs.gamescope.enable = true;
  programs.gamemode.enable = true;

  services.sunshine = {
    enable = true;
    package = pkgs.sunshine.override { cudaSupport = true; };
    autoStart = true;
    capSysAdmin = true;
    openFirewall = false;
  };

  networking.firewall.interfaces.tailscale0 = {
    allowedTCPPorts = [ 47984 47989 47990 48010 ];
    allowedUDPPortRanges = [{ from = 47998; to = 48000; }];
  };
}
