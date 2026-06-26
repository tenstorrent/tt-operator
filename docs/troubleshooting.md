# Troubleshooting

Start by capturing namespace state. See
[Collect diagnostics](continuous-operations.md#collect-diagnostics), then match the
symptom below.

## helm install fails with a cert-manager error

The error mentions `no matches for kind "Issuer"` or `"Certificate"`.
cert-manager is not installed, and the bundled `kubepmix` webhook needs it.
[Install cert-manager](prerequisites.md#cert-manager), or install without
kubepmix:

```bash
--set kubepmix.enabled=false
```

## helm install fails with a PodMonitor error

The error mentions `no matches for kind "PodMonitor"`. The Prometheus Operator
resources (`monitoring.coreos.com`) are not present, and tt-telemetry ships a
`PodMonitor` by default. Disable it:

```bash
--set tt-telemetry.podMonitor.enabled=false
```

You can still scrape `/metrics` by other means. See
[Telemetry](components/telemetry.md).

## Pods stuck in ImagePullBackOff

The node cannot pull from `ghcr.io`. Confirm outbound registry access and, if
your registry requires authentication, that a valid pull secret is configured.
Inspect the failing pod:

```bash
kubectl -n tt-operator-system describe pod <pod>
```

## NFD did not label a node

```bash
kubectl get nodes -l feature.node.kubernetes.io/pci-1200_1e52.present=true
```

If a node with a device is missing, confirm the device is visible on the host
with `lspci | grep -i tenstorrent`, and that the NFD worker pod is Running on
that node. Labeling is asynchronous, so allow a short interval after install.

## No /dev/tenstorrent devices on a node

The driver is not loaded. Check, in order:

```bash
kubectl get tenstorrentdriverpolicies                       # is a policy applied?
kubectl -n tt-operator-system get ds,pods                   # is the per-policy builder DaemonSet running?
cat /sys/module/tenstorrent/version                          # on the node, is the module loaded?
```

A common root cause is the builder failing to compile `tt-kmd` because the
node's kernel headers are missing. Inspect the builder pod logs:

```bash
kubectl -n tt-operator-system logs <driver-builder-pod>
```

## A ResourceClaim never binds (DRA)

```bash
kubectl get resourceslices
```

If there are no device entries, the [DRA Driver](components/dra.md) has no
resolvable fabric topology on the node, so it publishes nothing and the claim
cannot bind. This is an environment limitation, not a fault, and this path is
beta.

## Telemetry collector restarts during a driver install

This is expected. The device briefly disappears while `tt-kmd` is reinstalled and
the collector restarts. `/metrics` becomes healthy again once the driver is back.
See [Telemetry](components/telemetry.md).
