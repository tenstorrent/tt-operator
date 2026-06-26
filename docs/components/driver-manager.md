# Driver Manager

**Status: Supported**

The Driver Manager installs, upgrades, and node-scopes the Tenstorrent kernel
driver (`tt-kmd`) through a declarative custom resource. You describe the driver
version you want, and the operator builds and loads it on the matching nodes.

## How it works

Installing tt-operator deploys the Driver Manager controller and installs the
`TenstorrentDriverPolicy` custom resource definition. When you apply a policy,
the controller creates a per-policy DaemonSet on the matching nodes that builds
`tt-kmd` against the node's running kernel, loads it, and surfaces the device
nodes at `/dev/tenstorrent/`.

## Install a driver

```yaml
apiVersion: driver.tenstorrent.com/v1alpha1
kind: TenstorrentDriverPolicy
metadata:
  name: tt-kmd
spec:
  version: "2.8.0"          # tt-kmd version to install
  nodeSelector: {}          # ANDed with the NFD device-present label
  upgradePolicy:
    drain:
      enable: false         # cordon and drain before reload
      fullNode: false
    forceUnload: false
```

```bash
kubectl apply -f driver-policy.yaml
```

Confirm the module loaded and the devices appeared:

```bash
cat /sys/module/tenstorrent/version          # on the node, should report 2.8.0
ls /dev/tenstorrent/                          # one entry per device
kubectl get tenstorrentdriverpolicies
```

## Upgrade the driver

Change `spec.version` and re-apply. With `upgradePolicy.drain.enable: true`, the
controller cordons and drains the node, rebuilds and reloads the module to the
new version, then uncordons it. The host module version
(`/sys/module/tenstorrent/version`) is the source of truth that the new version
is live. Exactly one `tenstorrent` module remains loaded.

Driver upgrades also pause telemetry first so the collector releases the device.
See [Continuous Operations](../continuous-operations.md) and [Telemetry](telemetry.md).

## Scope to specific nodes

`spec.nodeSelector` is ANDed with the NFD device-present label, so a policy only
acts on nodes that both have a device and match your selector. This is useful for
staging a driver version on a subset of nodes:

```yaml
spec:
  nodeSelector:
    kubernetes.io/hostname: node-1
```

## Idempotency and removal

Re-applying an unchanged policy is a no-op. The controller reconciles to the
declared version and does nothing if the node is already there. Deleting the
policy, or uninstalling tt-operator, tears down the per-policy DaemonSet. By Helm
convention the custom resource definitions are not removed on `helm uninstall`.

## Configuration

The controller image and the per-node builder and flasher images are
overridable. See [Pinning component images](../installation.md#pin-component-images)
and the [Configuration reference](../configuration.md).
