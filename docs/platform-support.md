# Platform support

## Devices

tt-operator supports Tenstorrent **Wormhole** and **Blackhole** accelerators.
Both single-card and multi-card hosts are supported; the operator detects and
operates on every Tenstorrent device present on a node.

## Kubernetes

| Capability | Minimum Kubernetes |
|---|---|
| Core stack (NFD, driver, firmware, telemetry) | 1.27 |
| Device allocation via DRA *(beta)* | 1.33 |

## Validated environments

Each release is exercised end-to-end in CI on real Tenstorrent hardware:

- **RKE2** single-node clusters on Ubuntu hosts, across Wormhole (n150) and
  Blackhole (multi-card) runners — the full install → driver install/upgrade →
  firmware → telemetry → uninstall lifecycle.
- **kind** clusters (no hardware) for install-time and reconcile behavior across
  value permutations on every change.

Other conformant Kubernetes distributions are expected to work provided the
[prerequisites](prerequisites.md) are met, but RKE2 is what we validate against.

## Host requirements

- A Linux kernel for which `tt-kmd` can be built (the driver manager compiles the
  module against the node's kernel; headers/build tree must be available).
- Outbound access to `ghcr.io` for images (directly or via a mirror / pull
  secret).
- [cert-manager](prerequisites.md) for the bundled PMIx webhook.
