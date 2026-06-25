# Overview

tt-operator is an **umbrella Helm chart**. Installing it deploys a set of
cooperating components that take a node from "has a Tenstorrent card in it" to
"runs and monitors Tenstorrent workloads" — without hand-installing drivers or
wiring up device plugins.

## What it installs

| Component | Role |
|---|---|
| **Node Feature Discovery (NFD)** | Detects the Tenstorrent PCI device and labels the node so the other components (and your workloads) schedule only where hardware is present. |
| **Driver manager** (`tt-k8s-driver-manager`) | Installs, upgrades, and node-scopes the `tt-kmd` kernel driver and flashes firmware, all driven by Kubernetes custom resources. |
| **Telemetry** (`tt-telemetry`) | Collects per-device health and exposes it on a Prometheus `/metrics` endpoint. |
| **Fabric manager** (`tt-fabric-manager`) *(beta)* | Resolves inter-card / inter-host fabric topology and serves it to other components. |
| **DRA driver** (`tt-dra-driver`) *(beta)* | Publishes devices as schedulable resources via Kubernetes Dynamic Resource Allocation. |
| **JobSet + PMIx** (`jobset`, `kubepmix`) *(beta)* | Group and wire up multi-node jobs. |

Each component is a subchart that can be enabled or disabled independently — see
[Installation](installation.md) and the [Configuration reference](configuration.md).

## How the pieces fit together

```{mermaid}
flowchart TD
    NFD[Node Feature Discovery] -->|labels TT nodes| DM[Driver manager]
    NFD --> TEL[Telemetry]
    DM -->|installs tt-kmd, flashes firmware| DEV[(Tenstorrent device)]
    TEL -->|/metrics| PROM[Prometheus]
    FM[Fabric manager] -->|topology| DRA[DRA driver]
    FM -->|topology| TEL
    DRA -->|schedulable devices| WL[Workloads]
    DEV --- TEL
    DEV --- DRA
```

NFD labels the nodes; the driver manager brings up `tt-kmd` and firmware on those
nodes; telemetry reports device health; and (in beta) the fabric manager resolves
topology that the DRA driver and telemetry consume, while the DRA driver exposes
devices to workloads.

## Relationship to a vendor GPU operator

If you have used the NVIDIA GPU Operator, the model maps closely:

| NVIDIA GPU Operator | tt-operator |
|---|---|
| Driver container | Driver manager + `TenstorrentDriverPolicy` |
| Firmware (baked into driver) | `TenstorrentFirmwarePolicy` |
| Node Feature Discovery | Node Feature Discovery |
| DCGM / DCGM-exporter | Telemetry |
| Device plugin (`nvidia.com/gpu`) | DRA driver *(beta)* |
| NVLink fabric (in driver) | Fabric manager *(beta)* |

The main difference is that tt-operator manages the driver and firmware lifecycle
through **declarative policy custom resources** rather than a driver container, so
operations like upgrades and node scoping are expressed as Kubernetes objects you
apply and observe.
