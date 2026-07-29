# Tenstorrent Operator

tt-operator is the umbrella Helm chart that brings Tenstorrent devices under
Kubernetes management. It installs and coordinates the components that discover
Tenstorrent devices, install and upgrade the kernel-mode driver
([`tt-kmd`](https://github.com/tenstorrent/tt-kmd)), flash firmware, export device
telemetry, and make devices available to workloads.

This documentation is written for cluster administrators and platform operators
who install and run tt-operator. It is organized around the tasks you perform,
from first install through continuous operations.

```{toctree}
:maxdepth: 1
:caption: Get Started

overview
platform-support
release-notes
prerequisites
installation
```

```{toctree}
:maxdepth: 1
:caption: Configure and Operate

configuration
components/index
factory-system-descriptor
continuous-operations
troubleshooting
```

## Feature status

| Status | Meaning |
|---|---|
| **Supported** | Generally available in this release and covered by the documented workflows. |

| Component | Capability | Status |
|---|---|---|
| Node Feature Discovery | Labels nodes that have Tenstorrent devices | Supported |
| Driver Manager | Installs, upgrades, and scopes `tt-kmd` via policy resources | Supported |
| Firmware | Flashes device firmware via a policy resource | Supported |
| Telemetry | Exposes a Prometheus `/metrics` endpoint | Supported |
| Fabric Manager | Resolves fabric topology across devices and hosts | Supported |
| Device Allocation (DRA) | Publishes devices as schedulable resources | Supported |
| Multi-Node Scheduling | JobSet and PMIx wiring for multi-node jobs | Supported |
