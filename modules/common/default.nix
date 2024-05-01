{ config, inputs, pkgs, ... }:
{
  imports = [
    ./security.nix
    ./users.nix
    ./kernel.nix
    inputs.srvos.nixosModules.server
  ];
}
