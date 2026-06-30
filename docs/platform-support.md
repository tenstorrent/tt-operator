# Platform Support

## Devices

tt-operator supports Tenstorrent Wormhole and Blackhole devices. Hosts with one
or more Tenstorrent devices are supported. The operator detects and operates on
every Tenstorrent device present on a node.

## Kubernetes

| Capability | Minimum Kubernetes |
|---|---|
| Core stack (NFD, Driver Manager, Firmware, Telemetry) | 1.27 |
| Device Allocation via DRA *(beta)* | 1.33 |

## Host requirements

- A Linux kernel for which `tt-kmd` can be built. The Driver Manager compiles the
  module against the node's kernel, so the matching kernel headers must be
  available.
- Outbound access to `ghcr.io` for images, directly or via a mirror.
- [cert-manager](prerequisites.md) for the bundled PMIx webhook.

```{admonition} Reviewer note — confirm before v0.1
:class: danger
The outbound `ghcr.io` access requirement above is subject to change before the
v0.1 release. The published-artifacts registry and access model are still being
finalized, so this line must be confirmed and updated before shipping. Do not
miss this before release.
```
