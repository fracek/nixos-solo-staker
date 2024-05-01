{ config, lib, inputs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    inputs.self.nixosModules.common
    inputs.agenix.nixosModules.default
  ];

  age.secrets.tailscale.file = ./secrets/tailscale.age;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.useDHCP = lib.mkForce true;
  networking.hostName = "validator01";

  system.stateVersion = "23.11";
}
