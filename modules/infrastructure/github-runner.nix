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

  # SSH known_hosts for github-runner (github.com, shannon, feynman)
  environment.etc."ssh/ssh_known_hosts".text = ''
    github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl
    github.com ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCj7ndNxQowgcQnjshcLrqPEiiphnt+VTTvDP6mHBL9j1aNUkY4Ue1gvwnGLVlOhGeYrnZaMgRK6+PKCUXaDbC7qtbW8gIkhL7aGCsOr/C56SJMy/BCZfxd1nWzAOxSDPgVsmerOBYfNqltV9/hWCqBywINIR+5dIg6JTJ72pcEpEjcYgXkE2YEFXV1JHnsKgbLWNlhScqb2UmyRkQyytRLtL+38TGxkxCflmO+5Z8CSSNY7GidjMIZ7Q4zMjA2n1nGrlTDkzwDCsw+wqFPGQA179cnfGWOWRVruj16z6XyvxvjJwbz0wQZ75XK5tKSb7FNyeIEs4TT4jk+S4dhPeAUC5y+bDYirYgM4GC7uEnztnZyaVWQ7B381AK4Qdrwt51ZqExKbQpTUNn+EjqoTwvqNj4kqx5QUCI0ThS/YkOxJCXmPUWZbhjpCg56i+2aB6CmK2JGhn57K5mj0MNdBXA4/WnwH6XoPWJzK5Nyu2zB3nAZp+S5hpQs+p1vN1/wsjk=
    shannon ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDS8buEp8SU2tKN/4ZNA8PLNiyJRKHwPoG1THgFx3lzT
    10.0.0.1 ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDS8buEp8SU2tKN/4ZNA8PLNiyJRKHwPoG1THgFx3lzT
    feynman ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILLE89lhPvY7ZDVzLTVq2ZhVD8ypeVz8zXS8ZCYSk9SP
    10.0.1.3 ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILLE89lhPvY7ZDVzLTVq2ZhVD8ypeVz8zXS8ZCYSk9SP
  '';
  
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