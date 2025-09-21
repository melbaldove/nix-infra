{
  description = "Infrastructure configuration for all servers";
  
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    deploy-rs.url = "github:serokell/deploy-rs";
    agenix.url = "github:ryantm/agenix";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    
    # Import user configs from dotfiles
    dotfiles.url = "github:melbaldove/dotfiles";
  };
  
  outputs = { self, nixpkgs, deploy-rs, agenix, home-manager, dotfiles }@inputs: {
    # All host configurations
    nixosConfigurations = {
      shannon = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs self; };
        modules = [ 
          ./hosts/shannon/default.nix
        ];
      };
      
      newton = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs self; };
        modules = [ 
          ./hosts/newton/default.nix
        ];
      };
      
      einstein = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs self; };
        modules = [ 
          ./hosts/einstein/default.nix
        ];
      };
    };
    
    # Export modules for other repos to use
    nixosModules = {
      # Shared basics
      core = ./modules/shared/core.nix;
      ssh-keys = ./modules/shared/ssh-keys.nix;
      
      # Infrastructure services
      monitoring = ./modules/infrastructure/monitoring.nix;
      promtail = ./modules/shared/promtail.nix;
      node-exporter = ./modules/shared/node-exporter.nix;
      loki = ./modules/infrastructure/loki.nix;
      alertmanager = ./modules/infrastructure/alertmanager.nix;
      restic-backup = ./modules/infrastructure/restic-backup.nix;
      
      # Networking
      wireguard-server = ./modules/networking/wireguard-server.nix;
      wireguard-gateway = ./modules/networking/wireguard-gateway.nix;
      
      # Personal services
      media-server = ./modules/personal/media-server.nix;
      
      # Linux defaults
      linux-default = ./modules/linux/default.nix;
      linux-agenix = ./modules/linux/agenix.nix;
    };
    
    # Deployment configurations
    deploy.nodes = {
      shannon = {
        hostname = "shannon";
        remoteBuild = true;
        profiles.system = {
          user = "root";
          path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.shannon;
        };
      };
      
      newton = {
        hostname = "newton";
        profiles.system = {
          user = "root";
          path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.newton;
        };
      };
      
      einstein = {
        hostname = "einstein";
        profiles.system = {
          user = "root";
          path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.einstein;
        };
      };
    };
    
    checks = builtins.mapAttrs 
      (system: deployLib: deployLib.deployChecks self.deploy) 
      deploy-rs.lib;
  };
}