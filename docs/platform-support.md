# Platform support

## Devices

tt-operator supports Tenstorrent Wormhole and Blackhole devices. Hosts with one
or more Tenstorrent devices are supported. The operator detects and operates on
every Tenstorrent device present on a node.

## Kubernetes

| Capability | Minimum Kubernetes |
|---|---|
| Core stack (NFD, driver, firmware, telemetry) | 1.27 |
| Device allocation via DRA *(beta)* | 1.33 |

## Validated environments

Each release is exercised end to end in CI on real Tenstorrent hardware.

- **RKE2** single-node clusters on Ubuntu hosts, across Wormhole and Blackhole
  runners. Each run exercises the full lifecycle: install, driver install and
  upgrade, firmware, telemetry, and uninstall.
- **kind** clusters, without hardware, for install-time and reconcile behavior
  across value permutations on every change.

Other conformant Kubernetes distributions are expected to work provided the
[prerequisites](prerequisites.md) are met. RKE2 is what we validate against.

## Host requirements

- A Linux kernel for which `tt-kmd` can be built. The driver manager compiles the
  module against the node's kernel, so the matching kernel headers must be
  available.
- Outbound access to `ghcr.io` for images, directly or via a mirror or pull
  secret.
- [cert-manager](prerequisites.md) for the bundled PMIx webhook.
