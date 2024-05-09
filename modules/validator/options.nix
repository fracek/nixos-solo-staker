{ lib, ... }:
{
  options.services.validator = with lib; {
    enable = mkEnableOption (mdDoc "Ethereum validator setup");

    user = {
      name = mkOption {
        type = types.str;
        default = "validator";
        description = mdDoc "Service user.";
      };
      group = mkOption {
        type = types.str;
        default = "validator";
        description = mdDoc "Service group.";
      };
    };

    chain = mkOption {
      type = types.str;
      default = "holesky";
      description = mdDoc "On which network to run the validator";
    };

    validator-env = mkOption {
      type = types.path;
      description = mdDoc "Path to the environment file with fee recipient and graffiti";
    };

    nethermind = {
      metrics = {
        port = mkOption {
          type = types.port;
          default = 6060;
          description = mdDoc "Port for prometheus metrics";
        };
      };
    };

    prysm = {
      metrics = {
        port = mkOption {
          type = types.port;
          default = 8080;
          description = mdDoc "Port for prometheus metrics";
        };
      };
    };

    prysm-validator = {
      wallet-password = mkOption {
        type = types.path;
        description = mdDoc "Path to the wallet password file";
      };
      metrics = {
        port = mkOption {
          type = types.port;
          default = 8081;
          description = mdDoc "Port for prometheus metrics";
        };
      };
    };

    mev-boost = {
      min-bid = mkOption {
        type = types.str;
        default = "0.3";
        description = mdDoc "Minimum relay bid";
      };
      port = mkOption {
        type = types.port;
        default = 18550;
        description = mdDoc "Port for MEV Boost";
      };
      relays = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = mdDoc "List of relays to connect to";
      };
    };

    web3 = {
      jwtsecret = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = mdDoc "Path to the jwt secret";
      };
      host = mkOption {
        type = types.str;
        default = "127.0.0.1";
        description = mdDoc "Host for JSON-RPC server";
      };
      port = mkOption {
        type = types.port;
        default = 8551;
        description = mdDoc "Port for JSON-RPC server";
      };
    };
    sync = {
      checkpoint = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = mdDoc "Checkpoint URl for trusted sync";
      };
      genesis = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = mdDoc "Genesis URl for trusted sync";
      };
    };
  };
}
