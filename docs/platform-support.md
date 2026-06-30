# Platform Support

## Devices

tt-operator supports Tenstorrent Wormhole and Blackhole devices. Hosts with one
or more Tenstorrent devices are supported. The operator detects and operates on
every Tenstorrent device present on a node.

## Kubernetes

| Capability | Minimum Kubernetes |
|---|---|
| Core stack (NFD, Driver Manager, Firmware, Telemetry) | 1.27 |
| Device Allocation via DRA | 1.33 |

## Host requirements

- A Linux kernel for which `tt-kmd` can be built. The Driver Manager compiles the
  module against the node's kernel, so the matching kernel headers must be
  available.
- Outbound access to `ghcr.io` for images, directly or via a mirror.
- [cert-manager](prerequisites.md) for the bundled PMIx webhook.
