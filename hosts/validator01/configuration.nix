{ inputs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    inputs.self.nixosModules.common
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "validator01";

  system.stateVersion = "23.11";
}
