
{
  pkgs, lib, ...
}:
{
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs; [
    vim
    coreutils
    findutils
    jq
    tmux
    curl
    wget
  ];

  nixpkgs.config.allowUnfree = true;

  # Necessary for using flakes on this system.
  nix.settings = {
    experimental-features = "nix-command flakes";
    trusted-users = [ "root" "melbournebaldove" ];
    substituters = [
      "https://cache.nixos.org/"
      "https://nix-community.cachix.org"
      "https://nixpkgs-unfree.cachix.org"
      "https://devenv.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nixpkgs-unfree.cachix.org-1:hqvoInulhbV4nJ9yJOEr+4wxhDV4xq2d1DK7S6Nj6rs="
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
      # TODO: replace with nix-serve public key once generated
      "haeru-cache:m31dOHpFNZLXcN/Ts6luYMhDFvpqPjPBOkzioup9Q24="
    ];
  };
}
