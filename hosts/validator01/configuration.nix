{ config, lib, inputs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    inputs.agenix.nixosModules.default
    inputs.self.nixosModules.common
    inputs.self.nixosModules.validator
  ];

  services.validator = {
    enable = true;
    chain = "holesky";
    web3.jwtsecret = config.age.secrets.jwtsecret.path;
    sync = {
      checkpoint = "https://holesky.beaconstate.info/";
      genesis = "https://holesky.beaconstate.info/";
    };
  };

  age.secrets.tailscale.file = ./secrets/tailscale.age;
  age.secrets.password.file = ./secrets/password.age;
  age.secrets.jwtsecret = {
    file = ./secrets/jwtsecret.age;
    owner = config.services.validator.user.name;
    group = config.services.validator.user.group;
    mode = "0440";
  };


  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.useDHCP = lib.mkForce true;
  networking.hostName = "validator01";

  system.stateVersion = "23.11";
}
