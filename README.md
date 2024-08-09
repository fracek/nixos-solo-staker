# NixOS 🤝 Home staking

This repository contains my NixOS configuration for home staking.

## Overview

### Before you start

You should set the cachix cache to `nixos-solo-staking`.

```
cachix use nixos-solo-staking
```

### Testing the build

```
cachix watch-exec nixos-solo-staking nixos-rebuild -- build-vm --flake .#validator01
```

### Core

**Agenix**

All secrets are stored encrypted using agenix. Agenix makes them available to
programs by decrypting them on boot.

This means that after you install NixOS on a new machine, you must use that
machine's public ssh key to re-encrypt secrets. For this reason, all secrets
are stored in `hosts/<host>/secrets`.

**Tailscale**

The machine connects to a Tailscale network on boot so that it can be reached
from anywhere.

### Ethereum

We run the Nethermind execution layer node, and Prysm as consensus client and validator.
Nothing fancy here.

### Monitoring

**OpenTelemetry Collector**

We run one OpenTelemetry collector service to collect logs (from journald) and
metrics (from the clients and validator) and push them to Grafana Cloud.

**Grafana Cloud**

We use Grafana Cloud for monitoring the nodes. The reason I'm using Grafana
Cloud is simple: I can configure it to alert me if it stops receiving data from
the validator.
