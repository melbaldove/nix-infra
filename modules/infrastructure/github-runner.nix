{ config, lib, pkgs, ... }:

{
  # Setup secret for GitHub runner token
  age.secrets.github-runner-token = {
    file = ../../secrets/infrastructure/github-runner-token.age;
    owner = "github-runner";
    group = "github-runner";
    mode = "0400";
  };
  
  # Setup SSH key for GitHub runner
  age.secrets.github-runner-ssh-key = {
    file = ../../secrets/infrastructure/github-runner-ssh-key.age;
    owner = "github-runner";
    group = "github-runner";
    mode = "0600";
    path = "/var/lib/github-runner/.ssh/id_ed25519";
  };
  
  # GitHub Actions self-hosted runner
  services.github-runners = {
    haeru-runner = {
      enable = true;
      url = "https://github.com/haeru-app/haeru";
      tokenFile = config.age.secrets.github-runner-token.path;
      name = "einstein-runner";
      
      # Run as dedicated user
      user = "github-runner";
      group = "github-runner";
      
      # Extra packages available to the runner
      extraPackages = with pkgs; [
        docker
        nix
        git
        openssh
        deploy-rs
        curl
      ];
      
      # Labels for this runner
      extraLabels = [ "self-hosted" "linux" "x64" "einstein" "nix" ];
      
      # Keep runner online
      replace = true;
    };
  };
  
  # Create the github-runner user
  users.users.github-runner = {
    isSystemUser = true;
    group = "github-runner";
    home = "/var/lib/github-runner";
    createHome = true;
  };
  
  users.groups.github-runner = {};
  
  # Ensure the runner can use Nix
  nix.settings.trusted-users = [ "github-runner" ];
}