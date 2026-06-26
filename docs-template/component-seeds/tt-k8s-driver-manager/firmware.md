# Firmware

**Status: Supported**

The Driver Manager also flashes device firmware, driven by a
`TenstorrentFirmwarePolicy` custom resource. Applying a policy makes the operator
run a per-node flash Job that writes the requested firmware bundle to each
matching device.

## Flash firmware

```yaml
apiVersion: firmware.tenstorrent.com/v1alpha1
kind: TenstorrentFirmwarePolicy
metadata:
  name: tt-firmware
spec:
  version: "18.5.0"         # firmware bundle version to flash
  nodeSelector: {}          # ANDed with the NFD device-present label
  upgradePolicy:
    drain:
      enable: false         # cordon and drain before flashing
```

```bash
kubectl apply -f firmware-policy.yaml
kubectl get tenstorrentfirmwarepolicies
```

By default the bundle is downloaded from the Tenstorrent system-firmware
releases at
`https://github.com/tenstorrent/tt-system-firmware/releases/download/v<version>/fw_pack-<version>.fwbundle`.
Override the location with `spec.bundleURL` if you mirror it internally.

## Useful fields

| Field | Purpose |
|---|---|
| `spec.version` | Firmware bundle version to flash. |
| `spec.bundleURL` | Override the bundle download location, for example an internal mirror. |
| `spec.nodeSelector` | Restrict which nodes are flashed (ANDed with the device-present label). |
| `spec.upgradePolicy.drain` | Cordon and drain a node before flashing. |
| `spec.readbackVersion` | The version `tt-smi` should report after a successful flash. Defaults to `<version>.0`. |

The policy `.status` summarizes how many devices matched, are up to date, are in
progress, or failed.

```{note}
Firmware flashing changes device state. Flash during a maintenance window and
prefer `upgradePolicy.drain.enable: true` so workloads are evicted first.
```

See the [Configuration reference](../configuration.md) for the flasher image
overrides.
