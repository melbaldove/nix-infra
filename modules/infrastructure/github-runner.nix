{ config, lib, pkgs, ... }:

{
  # Setup secret for GitHub runner token
  age.secrets.github-runner-token = {
    file = ../../secrets/infrastructure/github-runner-token.age;
    owner = "melbournebaldove";
    group = "users";
    mode = "0400";
  };
  
  # GitHub Actions self-hosted runner
  services.github-runners = {
    haeru-runner = {
      enable = true;
      url = "https://github.com/haeru-app/haeru";
      tokenFile = config.age.secrets.github-runner-token.path;
      name = "einstein-runner";
      
      # Run as melbournebaldove to use existing SSH keys
      user = "melbournebaldove";
      group = "users";
      
      # Extra packages available to the runner
      extraPackages = with pkgs; [
        docker
        nix
        git
        openssh
        deploy-rs
      ];
      
      # Labels for this runner
      extraLabels = [ "self-hosted" "linux" "x64" "einstein" "nix" ];
      
      # Keep runner online
      replace = true;
    };
  };
  
  # Ensure melbournebaldove can use Nix (already should be able to)
  nix.settings.trusted-users = [ "melbournebaldove" ];
}