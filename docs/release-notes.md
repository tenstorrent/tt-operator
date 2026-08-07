# Release Notes

tt-operator ships as a single umbrella Helm chart. Each release pins one tested
set of component versions, so the chart version you install determines the
component versions you get. Upgrade the umbrella chart as a unit rather than
bumping individual subcharts.

## Component versions

| Component | v0.2.0 | v0.1.0 |
|---|---|---|
| [Driver Manager](https://docs.tenstorrent.com/tt-k8s-driver-manager/) | 0.0.6 | 0.0.5 |
| [Fabric Manager](https://docs.tenstorrent.com/tt-fabric-manager/) | 0.2.29 | 0.2.28 |
| [Device Allocation (DRA)](https://docs.tenstorrent.com/tt-dra-driver/) | 0.0.48 | 0.0.36 |
| [Telemetry](https://docs.tenstorrent.com/tt-telemetry/) | 0.2.0 | 0.1.1 |
| [Node Feature Discovery](https://github.com/kubernetes-sigs/node-feature-discovery) | 0.18.3 | 0.18.3 |
| [JobSet](https://github.com/kubernetes-sigs/jobset) | 0.12.0 | 0.12.0 |

## v0.2.0

Released 31 July 2026. A component refresh — the installed surface and the set
of supported capabilities are unchanged from v0.1.0.

### Upgrade notes

- The telemetry HTTP and Service ports change from `8080` to `18080`, so
  host-network collectors no longer collide with common application ports on the
  node. Update any scrape target, Service reference, or firewall rule that
  assumes `8080`. The aggregator NodePort is unchanged at `30080`.
- The telemetry collector DaemonSet memory limit rises to 3Gi.

### Driver Manager 0.0.5 → 0.0.6

- Node readiness is keyed on a file marker written after `tt-kmd` loads, so a
  node reports ready only once the driver is actually in place.
- The driver DaemonSet rolls with `maxUnavailable: 25%` instead of one node at a
  time, shortening cluster-wide driver rollouts.

### Fabric Manager 0.2.28 → 0.2.29

- Query supported topology shapes and retrieve topology instances through the
  controller, SDK, and CLI.
- Placement avoids fragmenting topology groups and reports ASIC location in the
  placement response.
- The CLI emits rank bindings and rankfiles for a computed placement.
- The web UI visualizes placements and offers rankfile download.
- The controller honors the `tenstorrent.com/deploy.tt-fabric-manager` node gate
  and prefers nodes without Tenstorrent devices.

### Device Allocation (DRA) 0.0.36 → 0.0.48

- Devices publish a `boardName` attribute matching the driver's sysfs string, so
  a `ResourceClaim` can select a specific board type — for example `n150`,
  `n300`, or `p150`.
- Corrected the Fabric Manager endpoint used for topology discovery.

### Telemetry 0.1.1 → 0.2.0

- Export metrics and logs to an OpenTelemetry collector, alongside the existing
  Prometheus endpoint.
- New metrics: count of host processes holding a Tenstorrent device, machine type
  and architecture, dispatch telemetry, and Ethernet link status read from ARC
  over UMD (unified with the existing link-up metric).
- Ethernet heartbeat restored on Blackhole.
- Falls back to monitoring all links when Fabric Manager reports no fabric state
  descriptor, instead of reporting nothing.
- New `instance_path` label on device metrics.
- The aggregator prefers nodes without Tenstorrent devices, leaving device nodes
  for workloads.

## v0.1.0

Released 1 July 2026. The first supported release: the components needed to run
Tenstorrent devices under Kubernetes, packaged as one umbrella chart and
validated end to end on Tenstorrent hardware.

- **One-step install** of the full stack from the published Helm chart.
- **Device discovery.** Nodes with Tenstorrent devices are labeled automatically,
  so workloads and operands schedule only where a device is present.
- **Driver lifecycle.** Install, upgrade, and node-scope `tt-kmd` declaratively
  with `TenstorrentDriverPolicy`. During an upgrade the node is cordoned and
  drained and telemetry is paused so it releases the device first.
- **Firmware flashing** via `TenstorrentFirmwarePolicy`.
- **Telemetry.** A Prometheus `/metrics` endpoint reporting per-device health
  with topology-aware identity labels.
- **Device allocation.** Devices published as schedulable DRA resources.
- **Multi-node scheduling.** JobSet and PMIx wiring for multi-node jobs.
- **Continuous operations.** In-place `helm upgrade` and clean `helm uninstall`.

See [Overview](overview.md) for how the components fit together,
[Prerequisites](prerequisites.md) for cluster requirements, and
[Platform Support](platform-support.md) for validated devices and environments.

## Earlier previews

v0.0.1 through v0.0.5 were pre-release iterations of the umbrella chart, ending
with the chart published to `ghcr.io/tenstorrent/helm`. They are not supported;
start at v0.1.0 or later.

## Known limitations

- Device allocation requires resolvable fabric topology on the node. On systems
  without staged topology, devices are not published as schedulable resources.
- Air-gapped and private-registry installs are not yet covered by a documented
  workflow.
