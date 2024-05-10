{ config, pkgs, lib, ... }:
let
  settingsFormat = pkgs.formats.yaml { };

  cfg = config.services.monitoring;

  servicesScrapeConfigs = map
    ({ unit, port, ... }: {
      job_name = "${unit}";
      scrape_interval = "30s";
      static_configs = [
        {
          targets = [
            "127.0.0.1:${builtins.toString port}"
          ];
        }
      ];
    })
    cfg.services;

  nodeExporterScrapeConfig = {
    job_name = config.networking.hostName;
    scrape_interval = "30s";
    static_configs = [
      {
        targets = [
          "127.0.0.1:${builtins.toString config.services.prometheus.exporters.node.port}"
        ];
      }
    ];
  };

  settings = {
    receivers = {
      journald = {
        directory = "/var/log/journal";
        units = map ({ unit, ... }: unit) cfg.services;
        priority = "info";
      };
      prometheus = {
        config = {
          scrape_configs = servicesScrapeConfigs ++ [ nodeExporterScrapeConfig ];
        };
      };
    };

    processors = {
      batch = { };
    };

    exporters = {
      prometheusremotewrite = {
        endpoint = "\${env:PROM_ENDPOINT}";
      };
      loki = {
        endpoint = "\${env:LOKI_ENDPOINT}";
      };
    };

    service = {
      pipelines = {
        logs = {
          receivers = [ "journald" ];
          processors = [ "batch" ];
          exporters = [ "loki" ];
        };

        metrics = {
          receivers = [ "prometheus" ];
          processors = [ "batch" ];
          exporters = [ "prometheusremotewrite" ];
        };
      };
    };
  };
in
{
  options.services.monitoring = with lib; {
    enable = mkEnableOption (mdDoc "Ethereum validator monitoring setup");

    user = mkOption {
      type = types.str;
      default = "prometheus";
    };

    otel-env = mkOption {
      type = types.path;
    };

    services = mkOption {
      type = types.listOf (types.submodule {
        options = {
          unit = mkOption {
            type = types.str;
          };
          port = mkOption {
            type = types.port;
          };
        };
      });
      default = [ ];
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.${cfg.user}.extraGroups = [ "systemd-journal" ];

    services.prometheus.exporters = {
      node = {
        enable = true;
        enabledCollectors = [ "systemd" ];
        port = 9002;
      };
    };

    systemd.services.opentelemetry-collector = {
      enable = true;
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      description = "OpenTelemetry Collector";
      serviceConfig =
        let
          conf = settingsFormat.generate "config.yaml" settings;
        in
        {
          ExecStart = "${lib.getExe pkgs.opentelemetry-collector-contrib} --config=file:${conf}";
          Restart = "always";
          User = cfg.user;
          EnvironmentFile = cfg.otel-env;
          ProtectSystem = "full";
          DevicePolicy = "closed";
          NoNewPrivileges = true;
          WorkingDirectory = "/var/lib/opentelemetry-collector";
          StateDirectory = "opentelemetry-collector";
        };
    };
  };
}
