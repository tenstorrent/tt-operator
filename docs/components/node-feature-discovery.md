---
orphan: true
---

# Device Labeling (Node Feature Discovery)

**Status: Supported**

tt-operator deploys [Node Feature Discovery](https://kubernetes-sigs.github.io/node-feature-discovery/)
(NFD) to detect Tenstorrent hardware and label the nodes that have it. Those
labels are what make the Driver Manager, telemetry, and your own workloads
schedule only where a device is present.

## What it does

NFD inspects each node's PCI devices and applies the label:

```
feature.node.kubernetes.io/pci-1200_1e52.present=true
```

to every node that has a Tenstorrent device (PCI vendor `1e52`). The chart
restricts NFD to the PCI source only, so it does not add the full set of CPU,
kernel, and system labels. This keeps node labels focused and the footprint
small.

## Verify

```bash
kubectl get nodes -l feature.node.kubernetes.io/pci-1200_1e52.present=true
```

Every node with a Tenstorrent device should be listed. If a node you expect is
missing, confirm the device is visible on the host with `lspci` and that the NFD
worker pod is running on that node.

## Configuration

NFD is enabled by default. To turn it off, for example if you already run NFD
cluster-wide, set:

```bash
--set node-feature-discovery.enabled=false
```

The feature and label sources are restricted to `pci` via
`node-feature-discovery.worker.config.core.featureSources` and `labelSources`.
See the [Configuration reference](../configuration.md) for the full set of NFD
values.
