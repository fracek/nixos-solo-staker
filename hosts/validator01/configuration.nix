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

  # Run a validator on the Holesky testnet
  services.validator = {
    enable = true;
    chain = "holesky";
    validator-env = config.age.secrets.validator-env.path;
    web3.jwtsecret = config.age.secrets.jwtsecret.path;
    prysm-validator.wallet-password = config.age.secrets.validator-wallet-password.path;
    mev-boost = {
      min-bid = "0.01";
      relays = [
        "https://0xafa4c6985aa049fb79dd37010438cfebeb0f2bd42b115b89dd678dab0670c1de38da0c4e9138c9290a398ecd9a0b3110@boost-relay-holesky.flashbots.net"
        "https://0xab78bf8c781c58078c3beb5710c57940874dd96aef2835e7742c866b4c7c0406754376c2c8285a36c630346aa5c5f833@holesky.aestus.live"
        "https://0xaa58208899c6105603b74396734a6263cc7d947f444f396a90f7b7d3e65d102aec7e5e5291b27e08d02c50a050825c2f@holesky.titanrelay.xyz"
      ];
    };
    sync = {
      checkpoint = "https://holesky.beaconstate.info/";
      genesis = "https://holesky.beaconstate.info/";
    };
  };

  # Monitor the validator services
  services.monitoring = {
    enable = true;
    user = config.services.validator.user.name;
    otel-env = config.age.secrets.otel-env.path;
    services = [
      {
        unit = "holesky-nethermind";
        port = config.services.validator.nethermind.metrics.port;
        labels = {
          "ethereum_network" = config.services.validator.chain;
          "service_name" = "nethermind";
        };
      }
      {
        unit = "holesky-prysm";
        port = config.services.validator.prysm.metrics.port;
        labels = {
          "ethereum_network" = config.services.validator.chain;
          "service_name" = "prysm-beacon-chain";
        };
      }
      {
        unit = "holesky-validator";
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
