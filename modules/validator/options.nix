{ lib, pkgs, ... }:
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
  };
}
