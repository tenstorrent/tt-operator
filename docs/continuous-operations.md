# Continuous Operations

## Upgrade tt-operator

Upgrade the release in place with Helm:

```bash
helm upgrade tt-operator oci://ghcr.io/tenstorrent/helm/tt-operator \
  --namespace tt-operator-system --reuse-values
```

Enabled controller Deployments roll to the new version and existing custom
resource definitions are preserved.

### Re-applying subchart CRDs

Subcharts ship their CRDs in their `crds/` directories. Helm applies them on
install only. `helm upgrade` deliberately skips them, the Helm 3 convention that
prevents a chart from silently changing CRD schemas under live resources. When
upgrading to a chart version that bumps a subchart whose CRD schema changed,
re-apply that subchart's CRDs yourself:

```bash
helm pull oci://ghcr.io/tenstorrent/helm/tt-operator --version <new> --untar -d /tmp/tt-operator-pull
kubectl apply --server-side --force-conflicts -f /tmp/tt-operator-pull/tt-operator/charts/<subchart>/crds/
helm upgrade tt-operator oci://ghcr.io/tenstorrent/helm/tt-operator --version <new> \
  -n tt-operator-system --reuse-values
```

`--server-side` is required because the JobSet CRD schema exceeds the
client-side apply annotation limit.

## Upgrade the driver

Driver version transitions are driven by the `TenstorrentDriverPolicy`, not by a
chart upgrade. Change `spec.version` and re-apply. With drain enabled, the
operator cordons and drains the node, rebuilds and reloads `tt-kmd`, then
uncordons it. Driver upgrades also pause telemetry first. The controller sets the
`tenstorrent.com/deploy.tt-telemetry` node gate to drain the collector so it
releases the device, then restores it once the new driver is ready. See the
[Driver Manager](https://docs.tenstorrent.com/tt-k8s-driver-manager/) component page.

## Uninstall

Remove any policy custom resources first, then uninstall the release:

```bash
kubectl delete tenstorrentdriverpolicies --all
kubectl delete tenstorrentfirmwarepolicies --all
helm uninstall tt-operator -n tt-operator-system
```

`helm uninstall` removes the operands, including the controllers, DaemonSets, and
telemetry. By Helm convention the custom resource definitions are not removed on
uninstall. Delete them explicitly if you want them gone:

```bash
kubectl delete crd tenstorrentdriverpolicies.driver.tenstorrent.com \
  tenstorrentfirmwarepolicies.firmware.tenstorrent.com
```

## Collect diagnostics

When something looks wrong, capture the namespace state before tearing anything
down:

```bash
kubectl get pods -A -o wide
kubectl -n tt-operator-system describe pods
kubectl -n tt-operator-system get ds,deploy,sa
kubectl get events -n tt-operator-system --sort-by=.lastTimestamp | tail -50
```

See [Troubleshooting](troubleshooting.md) for how to read the common failure
signals.
