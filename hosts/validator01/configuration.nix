{ config, lib, inputs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    inputs.agenix.nixosModules.default
    inputs.self.nixosModules.common
    inputs.self.nixosModules.validator
    inputs.self.nixosModules.monitoring
  ];

  # Secrets needed by other services
  age.secrets.tailscale.file = ./secrets/tailscale.age;
  age.secrets.password.file = ./secrets/password.age;
  age.secrets.jwtsecret = {
    file = ./secrets/jwtsecret.age;
    owner = config.services.validator.user.name;
    group = config.services.validator.user.group;
    mode = "0440";
  };
  age.secrets.otel-env = {
    file = ./secrets/otel-env.age;
    owner = config.services.validator.user.name;
    group = config.services.validator.user.group;
    mode = "0440";
  };
  age.secrets.validator-env = {
    file = ./secrets/validator-env.age;
    owner = config.services.validator.user.name;
    group = config.services.validator.user.group;
    mode = "0440";
  };
  age.secrets.validator-wallet-password = {
    file = ./secrets/validator-wallet-password.age;
    owner = config.services.validator.user.name;
    group = config.services.validator.user.group;
    mode = "0440";
  };

  # Run a validator on mainnet
  services.validator = {
    enable = true;
    chain = "mainnet";
    validator-env = config.age.secrets.validator-env.path;
    web3.jwtsecret = config.age.secrets.jwtsecret.path;
    prysm-validator.wallet-password = config.age.secrets.validator-wallet-password.path;
    mev-boost = {
      min-bid = "0.01";
      relays = [
        "https://0xa15b52576bcbf1072f4a011c0f99f9fb6c66f3e1ff321f11f461d15e31b1cb359caa092c71bbded0bae5b5ea401aab7e@aestus.live"
        "https://0x8c4ed5e24fe5c6ae21018437bde147693f68cda427cd1122cf20819c30eda7ed74f72dece09bb313f2a1855595ab677d@global.titanrelay.xyz"
        "https://0xac6e77dfe25ecd6110b8e780608cce0dab71fdd5ebea22a16c0205200f2f8e2e3ad3b71d3499c54ad14d6c21b41a37ae@boost-relay.flashbots.net"
      ];
    };
    sync = {
      checkpoint = "https://beaconstate.info/";
      genesis = "https://beaconstate.info/";
    };
  };

  # Monitor the validator services
  services.monitoring = {
    enable = true;
    user = config.services.validator.user.name;
    otel-env = config.age.secrets.otel-env.path;
    services = [
      {
        unit = "mainnet-nethermind";
        port = config.services.validator.nethermind.metrics.port;
        labels = {
          "ethereum_network" = config.services.validator.chain;
          "service_name" = "nethermind";
        };
      }
      {
        unit = "mainnet-prysm";
        port = config.services.validator.prysm.metrics.port;
        labels = {
          "ethereum_network" = config.services.validator.chain;
          "service_name" = "prysm-beacon-chain";
        };
      }
      {
        unit = "mainnet-validator";
        port = config.services.validator.prysm-validator.metrics.port;
        labels = {
          "ethereum_network" = config.services.validator.chain;
          "service_name" = "prysm-validator";
        };
      }
    ];
  };

  # Configuration specific to this machine

  # Automatically shutdown on power loss to avoid db corruption.
  services.apcupsd = {
    enable = true;
    configText = ''
      UPSTYPE usb
      NISIP 127.0.0.1

      BATTERYLEVEL 20
      MINUTES 5
    '';
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.useDHCP = lib.mkForce true;
  networking.hostName = "validator01";

  system.stateVersion = "23.11";
}
