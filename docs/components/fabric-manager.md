# Fabric manager

**Status: Beta.** Installed by default and usable for evaluation. Some
capabilities are still maturing and may change.

The Tenstorrent Fabric Manager (TTFM) resolves fabric topology across devices and
hosts and serves it over a gRPC API that other components consume, notably the
[DRA driver](dra.md), which uses it to place devices, and
[telemetry](telemetry.md), which uses it to label metrics with topology identity.

## What it deploys

- A controller Deployment that serves the topology API.
- A per-node agent DaemonSet that reports each node's local view.

Service names are rendered without the release prefix, for example
`tt-fabric-manager-controller` and `tt-fabric-manager-agent`, to match common
platform-component naming.

## Verify

```bash
kubectl -n tt-operator-system get deploy tt-fabric-manager-controller
kubectl -n tt-operator-system get ds tt-fabric-manager-agent
```

Both should report Ready replicas on nodes with devices.

## Configuration

For multi-host fabrics, an administrator typically overrides the cluster's node
grouping and the image pull secret. Consult the
[Configuration reference](../configuration.md) for the `tt-fabric-manager` values.
Most single-node setups do not need any fabric configuration.

```{note}
Topology resolution across multiple hosts is maturing. Single-node bring-up and
the topology service are available for evaluation now.
```
