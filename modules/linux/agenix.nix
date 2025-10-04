{ pkgs, inputs, ... }:
{
  environment.systemPackages = with pkgs; [
    inputs.agenix.packages.${pkgs.system}.default
  ];
}
