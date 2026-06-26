# Release notes

## tt-operator v0.1

The first release of the Tenstorrent Operator. tt-operator packages the
components needed to run Tenstorrent devices under Kubernetes into a single
umbrella Helm chart, validated end to end on real Tenstorrent hardware.

### Highlights

- **One-step install** of the full stack from the published Helm chart.
- **Tenstorrent device discovery.** Nodes that have Tenstorrent devices are
  automatically labeled, so workloads and operands schedule only where a
  Tenstorrent device is present.
- **Driver lifecycle.** Install, version-upgrade, and node-scope the `tt-kmd`
  kernel driver declaratively with the `TenstorrentDriverPolicy` resource. During
  an upgrade the operator cordons and drains the node and pauses telemetry so it
  releases the device first.
- **Firmware flashing** via the `TenstorrentFirmwarePolicy` resource.
- **Telemetry.** A Prometheus `/metrics` endpoint reporting per-device health,
  with topology-aware identity labels.
- **Continuous operations.** In-place `helm upgrade` and clean `helm uninstall`.

### Supported features

| Capability | Resource or surface |
|---|---|
| Device labeling | Node Feature Discovery PCI label |
| Driver install, upgrade, scoping | `TenstorrentDriverPolicy` |
| Firmware flashing | `TenstorrentFirmwarePolicy` |
| Telemetry | Prometheus `/metrics` |

### Beta features

The following components are installed by default and available for evaluation.
Their core behavior works today. Some capabilities are still maturing and may
change.

- **Fabric Manager.** Topology resolution across devices and hosts.
- **Device Allocation (DRA).** Publishing devices as schedulable resources via
  Kubernetes Dynamic Resource Allocation.
- **Multi-Node Scheduling.** JobSet plus PMIx environment injection for
  multi-node jobs.

### Requirements

- Kubernetes 1.27 or later. The Dynamic Resource Allocation beta features require
  1.33 or later.
- cert-manager installed on the cluster. It is required by the bundled PMIx
  admission webhook. See [Prerequisites](prerequisites.md).
- Network access to the container registry hosting the Tenstorrent images.

See [Platform support](platform-support.md) for the validated devices and
environments.

### Known limitations

- Device Allocation (DRA) requires resolvable fabric topology on the node. On
  systems without staged topology, devices are not yet published as schedulable
  resources.
- Air-gapped and private-registry installs are not yet covered by a documented
  workflow.
- The deeper per-feature capabilities of the beta components above are not yet
  part of the supported surface.
