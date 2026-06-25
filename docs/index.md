# Tenstorrent Operator

`tt-operator` is the umbrella Helm chart that brings Tenstorrent accelerators
under Kubernetes management. It installs and coordinates the components that
discover Tenstorrent devices, install and upgrade the kernel-mode driver
(`tt-kmd`), flash firmware, export device telemetry, and expose devices to
workloads — the Tenstorrent counterpart to a vendor GPU operator.

This documentation is written for **cluster administrators and platform/SRE
users** who install and operate tt-operator. It is organized around the tasks
you actually perform, from first install through day-2 operations.

```{toctree}
:maxdepth: 1
:caption: Get started

overview
platform-support
release-notes
prerequisites
installation
```

```{toctree}
:maxdepth: 1
:caption: Configure & operate

configuration
components/index
day-2-operations
troubleshooting
```

## Feature status

| Status | Meaning |
|---|---|
| **Supported** | Generally available in this release and covered by the documented workflows. |
| **Beta** | Installed by default and usable for evaluation; some capabilities are still maturing and may change. |

| Component | Capability | Status |
|---|---|---|
| Node Feature Discovery | Labels nodes that have Tenstorrent devices | Supported |
| Driver manager | Installs / upgrades / scopes `tt-kmd` via policy CRDs | Supported |
| Firmware | Flashes device firmware via a policy CRD | Supported |
| Telemetry | Exposes a Prometheus `/metrics` endpoint | Supported |
| Fabric manager | Resolves inter-card / inter-host topology | Beta |
| Device allocation (DRA) | Publishes devices as schedulable resources | Beta |
| Multi-node scheduling | JobSet + PMIx wiring for multi-node jobs | Beta |
