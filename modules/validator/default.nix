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
      pkgs.prysm
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

    networking.firewall = {
      # https://docs.nethermind.io/fundamentals/security/
      # https://docs.prylabs.network/docs/prysm-usage/p2p-host-ip
      allowedUDPPorts = [
        30303
        12000
      ];
      allowedTCPPorts = [
        30303
        13000
      ];
    };

    systemd.services."${cfg.chain}-nethermind" =
      let
        stateDir = "${cfg.chain}-nethermind";
        scriptArgs = lib.strings.concatStringsSep " " [
          "--datadir %S/${stateDir}"
          "--config ${cfg.chain}"
          "--Sync.SnapSync true"
          "--Metrics.Enabled true"
          "--Metrics.ExposeHost 127.0.0.1"
          "--Metrics.ExposePort ${builtins.toString cfg.nethermind.metrics.port}"
          "--Metrics.NodeName ${cfg.chain}-nethermind"
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
            Restart = "on-failure";
            User = cfg.user.name;
            StateDirectory = stateDir;
            ExecStart = "${pkgs.nethermind}/bin/nethermind ${scriptArgs}";
          }
          (lib.mkIf (cfg.web3.jwtsecret != null) {
            LoadCredential = [ "jwtsecret:${cfg.web3.jwtsecret}" ];
          })
        ];
      };

    systemd.services."${cfg.chain}-prysm" =
      let
        stateDir = "${cfg.chain}-prysm";
        executionEndpoint = "http://${cfg.web3.host}:${builtins.toString cfg.web3.port}";
        checkpointSyncArgs = if cfg.sync.checkpoint == null then [ ] else [
          "--checkpoint-sync-url=${cfg.sync.checkpoint}"
        ];
        genesisSyncArgs = if cfg.sync.genesis == null then [ ] else [
          "--genesis-beacon-api-url=${cfg.sync.genesis}"
        ];
        scriptArgs = lib.strings.concatStringsSep " " (checkpointSyncArgs ++ genesisSyncArgs ++ [
          "--accept-terms-of-use"
          "--datadir=%S/${stateDir}"
          "--${cfg.chain}"
          "--jwt-secret=%d/jwtsecret"
          "--execution-endpoint=${executionEndpoint}"
          "--monitoring-host=127.0.0.1"
          "--monitoring-port=${builtins.toString cfg.prysm.metrics.port}"
        ]);
      in
      {
        enable = true;
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        description = "Prism - ${cfg.chain}";
        serviceConfig = lib.mkMerge [
          {
            Restart = "on-failure";
            User = cfg.user.name;
            StateDirectory = stateDir;
            ExecStart = "${pkgs.prysm}/bin/beacon-chain ${scriptArgs}";
          }
          (lib.mkIf (cfg.web3.jwtsecret != null) {
            LoadCredential = [ "jwtsecret:${cfg.web3.jwtsecret}" ];
          })
        ];
      };

    services.opentelemetry-collector = {
      enable = true;
      package = pkgs.opentelemetry-collector-contrib;
      settings = {
        receivers = {
          journald = {
            directory = "/var/log/journal";
            units = [
              "${cfg.chain}-nethermind"
              "${cfg.chain}-prysm"
            ];
            priority = "info";
          };
          prometheus = {
            config = {
              scrape_configs = [
                {
                  job_name = "${cfg.chain}-nethermind";
                  scrape_interval = "10s";
                  static_configs = [
                    {
                      targets = [
                        "127.0.0.1:${builtins.toString cfg.nethermind.metrics.port}"
                      ];
                    }
                  ];
                }
                {
                  job_name = "${cfg.chain}-prysm";
                  scrape_interval = "10s";
                  static_configs = [
                    {
                      targets = [
                        "127.0.0.1:${builtins.toString cfg.prysm.metrics.port}"
                      ];
                    }
                  ];
                }
              ];
            };
          };
        };

        processors = {
          batch = { };
        };

        exporters = {
          debug = { };
        };

        service = {
          pipelines = {
            logs = {
              receivers = [ "journald" ];
              processors = [ "batch" ];
              exporters = [ "debug" ];
            };

            metrics = {
              receivers = [ "prometheus" ];
              processors = [ "batch" ];
              exporters = [ "debug" ];
            };
          };
        };
      };
    };
  };
}
