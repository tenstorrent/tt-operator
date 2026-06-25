# Fabric manager

**Status: Beta** — installed by default and usable for evaluation; some
capabilities are still maturing and may change.

The Tenstorrent Fabric Manager (TTFM) resolves inter-card and inter-host fabric
topology and serves it over a gRPC API that other components consume — notably
the [DRA driver](dra.md) (to place devices) and [telemetry](telemetry.md) (to
label metrics with topology identity).

## What it deploys

- a **controller** Deployment that serves the topology API, and
- a per-node **agent** DaemonSet that reports each node's local view.

Service names are rendered without the release prefix (e.g.
`tt-fabric-manager-controller`, `tt-fabric-manager-agent`) to match common
platform-component naming.

## Verify

```bash
kubectl -n tt-operator-system get deploy tt-fabric-manager-controller
kubectl -n tt-operator-system get ds tt-fabric-manager-agent
```

Both should report Ready replicas on nodes with devices.

## Configuration

For multi-host fabrics, an administrator typically overrides the cluster's node
grouping and the image pull secret; consult the
[Configuration reference](../configuration.md) for the `tt-fabric-manager` values.
Most single-node setups do not need any fabric configuration.

```{note}
Deep topology features (multi-host link/topology resolution) are maturing.
Single-node bring-up and the topology service are available for evaluation now.
```
