{ config, lib, pkgs, ... }:

{
  users.users.melbournebaldove.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINvRFinX32oEn1D4pBUmAZdmk+LofsuMG9rpmv87U0at melbournebaldove@Turing.local"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJuJUmdNbq46Ge0V0ZnU9dwspG7ge9CNEeBcNFZWSKVK melbournebaldove@einstein"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL9kxNdfEm/cwRLiYX5JokRQTnb2//LMXHJFR4SYnTxA github-runner@einstein"
  ];
  
  # Add deploy user for GitHub Actions deployments from einstein
  users.users.deploy = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];  # Give sudo access for deployments
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL9kxNdfEm/cwRLiYX5JokRQTnb2//LMXHJFR4SYnTxA github-runner@einstein"
    ];
  };
}