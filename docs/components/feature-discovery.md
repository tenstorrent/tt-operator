---
orphan: true
---

# Hardware Labels (Feature Discovery)

**Status: Supported**

tt-operator deploys Feature Discovery (`tt-feature-discovery`) next to
[Node Feature Discovery](node-feature-discovery.md) to describe *what*
Tenstorrent hardware a node has. The NFD PCI label only says a device is
present. Feature Discovery adds `tenstorrent.com/*` labels for the accelerator
family, board product, and count, and, with the Fabric Manager, the node's place
in the fabric and the datacenter. Use them in node selectors and affinities to
place workloads on the right hardware.

## How it works

A per-node DaemonSet scans the PCI bus under `/sys` and writes a feature file
into NFD's local feature-file directory on the node. The NFD worker on the same
node turns that file into node labels. Feature Discovery never contacts the API
server and has no ServiceAccount. The chart enables NFD's `local` source for
this.

A node with no Tenstorrent device publishes no `tenstorrent.com/*` labels, which
is also how a stale label is removed from a node that lost its hardware.

## Labels

### From the PCI bus

These need nothing installed on the host, not even the driver, so a node is
classifiable before anything Tenstorrent-specific runs on it.

| Label | Example | Meaning |
|---|---|---|
| `tenstorrent.com/device.present` | `true` | The host has at least one Tenstorrent PCI device. |
| `tenstorrent.com/accelerator.count` | `8` | Tenstorrent PCI endpoints on the host. |
| `tenstorrent.com/accelerator.family` | `wormhole` | ASIC generation, from the PCI device ID. |
| `tenstorrent.com/accelerator.product` | `n150` | Board type, from the board ID on the PCI subsystem. |

Known products are `n150`, `n300`, `galaxy`, `ubb`, `ubb_blackhole`, `p100`,
`p150`, and `p300`. A card this build does not recognize is still counted and
labeled `unknown`. The values match `tt-smi` and cluster-descriptor output.

`accelerator.count` counts PCI endpoints, not ASICs. On an N300 only one of the
two ASICs is PCIe-attached, so the Fabric Manager's `asic.count` is higher. On a
UBB Galaxy (`ubb` or `ubb_blackhole`) every ASIC is an endpoint, so a Galaxy host
reports `accelerator.count=32` for one baseboard. `product=galaxy` is the older
single-ASIC board, not a Galaxy system.

A host with two card types gets `family=mixed` or `product=mixed`, with the full
set published beside it as `accelerator.families` or `accelerator.products`
(values joined with `.`). A selector for one family therefore never matches a
mixed node.

### From the Fabric Manager

These are published when `tt-feature-discovery.fabricManager.address` points at
the Fabric Manager controller and its agent is registered for the node. They are
best-effort and never block the PCI labels.

| Label | Example | Meaning |
|---|---|---|
| `tenstorrent.com/asic.count` | `8` | ASICs the Fabric Manager sees on the host. |
| `tenstorrent.com/asic.arch` | `wormhole_b0` | ASIC architecture. |
| `tenstorrent.com/datacenter.hall` | `aus2` | Physical location from the factory system descriptor. |
| `tenstorrent.com/datacenter.aisle` | `a1` | Physical location. |
| `tenstorrent.com/datacenter.rack` | `12` | Physical location. |
| `tenstorrent.com/datacenter.shelf-u` | `34` | Physical location. |
| `tenstorrent.com/fabric.connected-hosts` | `2` | Hosts reachable through this host's exit nodes. |
| `tenstorrent.com/fabric.group` | `110-sc36_4x4_c1-10` | This host's connectivity group. |
| `tenstorrent.com/fabric.group-size` | `3` | Hosts in the group. |
| `tenstorrent.com/fabric.group-topology` | `bh-glx-sc4` | Topology type the group is a complete instance of. |
| `tenstorrent.com/fabric.pod` | `...-bh_glx_pod_2` | This host's pod within the group. |
| `tenstorrent.com/fabric.pod-size` | `2` | Hosts in the pod. |
| `tenstorrent.com/fabric.pod-topology` | `bh-glx-sc2` | Topology type the pod is a complete instance of. |
| `tenstorrent.com/fabric.source` | `psd-fsd` | Which views the Fabric Manager had: `psd`, `fsd`, or both. |

A cluster with no factory system descriptor loaded still gets the `asic.*`
labels, but no `datacenter.*` labels. If the Fabric Manager becomes unreachable,
the last known fabric labels keep being published for
`tt-feature-discovery.fabricManager.maxStale` (default 30 minutes) and then
drop.

## Verify

```bash
kubectl get nodes -l tenstorrent.com/device.present=true \
  -L tenstorrent.com/accelerator.family,tenstorrent.com/accelerator.product,tenstorrent.com/accelerator.count
```

Every node with a Tenstorrent device should be listed with its family, product,
and count. If a node is missing, see
[Troubleshooting](../troubleshooting.md#no-tenstorrentcom-labels-on-a-node).

## Configuration

Feature Discovery is enabled by default. To turn it off:

```bash
--set tt-feature-discovery.enabled=false
```

The fabric labels are wired to the in-cluster Fabric Manager controller by
default. If you disable the Fabric Manager, clear the address so the DaemonSet
stops querying it:

```bash
--set tt-fabric-manager.enabled=false \
--set tt-feature-discovery.fabricManager.address=""
```

Feature Discovery depends on NFD's `local` source, which the chart enables. If
you run your own NFD instead of the bundled one, keep `local` in its feature and
label sources and mount the same feature-file directory,
`/etc/kubernetes/node-feature-discovery/features.d`. See the
[Configuration reference](../configuration.md) for every value.
