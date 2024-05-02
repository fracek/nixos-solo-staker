{ config, inputs, pkgs, lib, ... }:
let
  options = import ./options.nix { inherit lib pkgs; };
  cfg = config.services.validator;
in
{
  inherit (options) options;

  imports = [
    inputs.ethereum.nixosModules.default
  ];

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.nethermind
      pkgs.nimbus
    ];

    users.users = {
      "${cfg.user.name}" = {
        useDefaultShell = true;
        isNormalUser = true;
        extraGroups = [
          cfg.user.group
        ];
      };
    };

    systemd.services."${cfg.chain}-nethermind" =
      let
        stateDir = "${cfg.chain}-nethermind";
        scriptArgs = lib.strings.concatStringsSep " " [
          "--datadir %S/${stateDir}"
          "--config ${cfg.chain}"
          "--Sync.SnapSync true"
          "--JsonRpc.JwtSecretFile %d/jwtsecret"
          "--JsonRpc.EngineHost ${cfg.web3.host}"
          "--JsonRpc.EnginePort ${builtins.toString cfg.web3.port}"
        ];
      in
      {
        enable = true;
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        description = "Nethermind - ${cfg.chain}";
        serviceConfig = lib.mkMerge [
          {
            User = cfg.user.name;
            StateDirectory = stateDir;
            ExecStart = "${pkgs.nethermind}/bin/nethermind ${scriptArgs}";
          }
          (lib.mkIf (cfg.web3.jwtsecret != null) {
            LoadCredential = [ "jwtsecret:${cfg.web3.jwtsecret}" ];
          })
        ];
      };

    /*
    systemd.services."${cfg.chain}-nimbus" =
      let
        stateDir = "${cfg.chain}-nimbus";
        elUrl = "http://${cfg.web3.host}:${cfg.web3.port}";
        scriptArgs = lib.strings.concatStringsSep " " [
          "--datadir %S/${stateDir}"
          "--network ${cfg.chain}"
          "--jwt-secret %d/jwtsecret"
          "--rest"
          "--el=${elUrl}"
        ];
      in
      {
        enable = true;
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        description = "Nimbus - ${cfg.chain}";
        serviceConfig = lib.mkMerge [
          {
            User = cfg.user.name;
            StateDirectory = stateDir;
            ExecStart = "${pkgs.nimbus}/bin/nimbus ${scriptArgs}";
          }
          (lib.mkIf (cfg.web3.jwtsecret != null) {
            LoadCredential = [ "jwtsecret:${cfg.web3.jwtsecret}" ];
          })
        ];
      };
      */
  };
}
