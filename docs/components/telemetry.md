# Telemetry

**Status: Supported**

tt-telemetry collects per-device health and exposes it on a Prometheus
`/metrics` endpoint. A collector runs on every Tenstorrent node and reports the
state of each device on that node.

## Metrics

The collector serves Prometheus metrics including `tt_driver_initialized`, a
gauge that reads `1` once the driver is up on the host. Per-device metrics carry
topology identity labels (`tray` and `chip`) sourced from the device's physical
system descriptor, so you can attribute a metric to a specific tray and chip.

Scrape the endpoint directly to check it:

```bash
kubectl -n tt-operator-system port-forward <telemetry-collector-pod> 8080:8080
curl -s localhost:8080/metrics | grep tt_driver_initialized
```

## Prometheus integration

tt-telemetry ships a `PodMonitor` for the Prometheus Operator. If your cluster
runs the Prometheus Operator, the collector is discovered and scraped
automatically. If it does not, because the `monitoring.coreos.com` resources are
absent, disable the PodMonitor to avoid an install-time error:

```bash
--set tt-telemetry.podMonitor.enabled=false
```

You can still scrape the endpoint by other means.

## Resilience

The collector tolerates device and driver churn. During a `tt-kmd` reinstall the
device briefly disappears and the collector may restart, but `/metrics` becomes
healthy again once the driver is back. This is expected and not an error.

## Topology identity

The collector can resolve richer topology from the [fabric manager](fabric-manager.md)
via `tt-telemetry.config.fabric_manager_address`. Where no topology is staged,
the collector falls back to monitoring all device channels. Metrics remain
available either way.

## Configuration notes

- **Namespace.** tt-telemetry sets its namespace explicitly. If you install
  tt-operator into a namespace other than `tt-operator-system`, set
  `tt-telemetry.namespace` to match. See
  [Installation](../installation.md#install-into-a-different-namespace).
- **Image.** Pin with `tt-telemetry.image.repository` and
  `tt-telemetry.image.tag`.

See the [Configuration reference](../configuration.md) for all telemetry values.
