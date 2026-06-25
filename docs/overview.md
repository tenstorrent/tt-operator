# Overview

tt-operator is an umbrella Helm chart. Installing it deploys a set of cooperating
components that take a node from having Tenstorrent devices installed to running
and monitoring Tenstorrent workloads, without hand-installing drivers or wiring
up device plugins.

## What it installs

| Component | Role |
|---|---|
| **Node Feature Discovery (NFD)** | Detects the Tenstorrent PCI device and labels the node, so the other components and your workloads schedule only where hardware is present. |
| **Driver manager** (`tt-k8s-driver-manager`) | Installs, upgrades, and node-scopes the `tt-kmd` kernel driver and flashes firmware, all driven by Kubernetes custom resources. |
| **Telemetry** (`tt-telemetry`) | Collects per-device health and exposes it on a Prometheus `/metrics` endpoint. |
| **Fabric manager** (`tt-fabric-manager`) *(beta)* | Resolves fabric topology across devices and hosts and serves it to other components. |
| **DRA driver** (`tt-dra-driver`) *(beta)* | Publishes devices as schedulable resources via Kubernetes Dynamic Resource Allocation. |
| **JobSet and PMIx** (`jobset`, `kubepmix`) *(beta)* | Group and wire up multi-node jobs. |

Each component is a subchart that can be enabled or disabled independently. See
[Installation](installation.md) and the [Configuration reference](configuration.md).

## How the pieces fit together

```{mermaid}
flowchart TD
    NFD[Node Feature Discovery] -->|labels nodes| DM[Driver manager]
    NFD --> TEL[Telemetry]
    DM -->|installs tt-kmd, flashes firmware| DEV[(Tenstorrent device)]
    TEL -->|/metrics| PROM[Prometheus]
    FM[Fabric manager] -->|topology| DRA[DRA driver]
    FM -->|topology| TEL
    DRA -->|schedulable devices| WL[Workloads]
    DEV --- TEL
    DEV --- DRA
```

NFD labels the nodes. The driver manager brings up `tt-kmd` and firmware on those
nodes. Telemetry reports device health. In beta, the fabric manager resolves
topology that the DRA driver and telemetry consume, and the DRA driver makes
devices available to workloads.

tt-operator manages the driver and firmware lifecycle through declarative policy
custom resources, so operations such as upgrades and node scoping are expressed
as Kubernetes objects that you apply and observe.
