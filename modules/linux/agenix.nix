{ pkgs, inputs, ... }:

{
  imports = [
    inputs.agenix.nixosModules.default
  ];

  environment.systemPackages = with pkgs; [
    inputs.agenix.packages.${pkgs.system}.default
  ];
}