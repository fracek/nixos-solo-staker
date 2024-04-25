{ inputs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    inputs.self.nixosModules.common
  ];

  networking.hostName = "validator01";

  system.stateVersion = "23.11";
}
