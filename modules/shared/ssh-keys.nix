{ config, lib, pkgs, ... }:

{
  users.users.melbournebaldove.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINvRFinX32oEn1D4pBUmAZdmk+LofsuMG9rpmv87U0at melbournebaldove@Turing.local"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJuJUmdNbq46Ge0V0ZnU9dwspG7ge9CNEeBcNFZWSKVK melbournebaldove@einstein"
  ];
  
  # Add runner user for GitHub Actions deployments
  users.users.runner = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];  # Give sudo access for deployments
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGeQYsbkqQwg5G38Y8a0/wDS7zjfaYogk+NDzaCh62bz haeru-deploy@github-actions"
    ];
  };
}