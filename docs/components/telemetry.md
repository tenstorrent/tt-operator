# Telemetry

**Status: Supported**

tt-telemetry collects per-device health and exposes it on a Prometheus
`/metrics` endpoint. A collector runs on every Tenstorrent node and reports the
state of each device on that node.

## Metrics

The collector serves Prometheus metrics including `tt_driver_initialized` (a
gauge that reads `1` once the driver is up on the host). Per-device metrics carry
**topology identity labels** (`tray`, `chip`) sourced from the device's physical
system descriptor, so you can attribute a metric to a specific card and chip.

Scrape the endpoint directly to sanity-check it:

```bash
kubectl -n tt-operator-system port-forward <telemetry-collector-pod> 8080:8080
curl -s localhost:8080/metrics | grep tt_driver_initialized
```

## Prometheus integration

tt-telemetry ships a `PodMonitor` for the Prometheus Operator. If your cluster
runs the Prometheus Operator, the collector is discovered and scraped
automatically. If it does **not** (the `monitoring.coreos.com` CRDs are absent),
disable the PodMonitor to avoid an install-time error:

```bash
--set tt-telemetry.podMonitor.enabled=false
```

You can still scrape the endpoint by other means.

## Resilience

The collector tolerates device/driver churn: during a `tt-kmd` (re)install the
device briefly disappears and the collector may restart, but `/metrics` becomes
healthy again once the driver is back. This is expected and not an error.

## Topology identity

The collector can resolve richer topology from the [fabric manager](fabric-manager.md)
via `tt-telemetry.config.fabric_manager_address`. Where no topology is staged,
the collector falls back to monitoring all device channels — metrics remain
available either way.

## Configuration notes

- **Namespace** — tt-telemetry hardcodes its namespace. If you install
  tt-operator into a namespace other than `tt-operator-system`, set
  `tt-telemetry.namespace` to match (see [Installation](../installation.md#install-into-a-different-namespace)).
- **Image** — pin with `tt-telemetry.image.repository` / `tt-telemetry.image.tag`.

See the [Configuration reference](../configuration.md) for all telemetry values.
