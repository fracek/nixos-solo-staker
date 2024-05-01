{ config, lib, inputs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    inputs.self.nixosModules.common
    inputs.agenix.nixosModules.default
  ];

  age.secrets.tailscale.file = ./secrets/tailscale.age;

  environment.variables = {
    TAILSCALE_TEST = config.age.secrets.tailscale.path;
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.useDHCP = lib.mkForce true;
  networking.hostName = "validator01";

  system.stateVersion = "23.11";
}
