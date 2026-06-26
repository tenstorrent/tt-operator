# Overview

tt-operator is an umbrella Helm chart. Installing it deploys a set of cooperating
components that take a node from having Tenstorrent devices installed to running
and monitoring Tenstorrent workloads, without hand-installing drivers or wiring
up device plugins.

## What it installs

| Component | Role |
|---|---|
| **Node Feature Discovery** | Labels nodes that have a Tenstorrent device. |
| **Driver Manager** | Installs, upgrades, and scopes the `tt-kmd` driver, and flashes firmware. |
| **Telemetry** | Exposes device health on a Prometheus endpoint. |
| **Fabric Manager** *(beta)* | Resolves fabric topology across devices and hosts. |
| **DRA Driver** *(beta)* | Publishes devices as schedulable resources via Kubernetes Dynamic Resource Allocation. |
| **Multi-Node Scheduling** *(beta)* | Groups and wires up multi-node jobs. |

Each component can be enabled or disabled independently. See
[Installation](installation.md) and the [Configuration reference](configuration.md).

## How the pieces fit together

```{mermaid}
flowchart TD
    NFD[Node Feature Discovery] -->|labels nodes| DM[Driver Manager]
    NFD -->|labels nodes| TEL[Telemetry]
    DM -->|installs tt-kmd, flashes firmware| DEV[(Tenstorrent device)]
    TEL -->|/metrics| PROM[Prometheus]
    FM[Fabric Manager] -->|topology| DRA[DRA Driver]
    FM -->|topology| TEL
    DRA -->|schedulable devices| WL[Workloads]
    DEV --- TEL
    DEV --- DRA
```

Node Feature Discovery labels the nodes. The Driver Manager brings up `tt-kmd`
and firmware on those nodes. Telemetry reports device health.

The beta components extend this. The Fabric Manager resolves topology that the
DRA Driver and Telemetry consume, and the DRA Driver makes devices available to
workloads.

tt-operator manages the driver and firmware lifecycle through declarative policy
custom resources, so operations such as upgrades and node scoping are expressed
as Kubernetes objects that you apply and observe.
