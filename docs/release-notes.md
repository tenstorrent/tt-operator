# Release Notes

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
| Fabric topology resolution | Fabric Manager gRPC API |
| Device allocation | Dynamic Resource Allocation (`ResourceClaim`) |
| Multi-node scheduling | JobSet and PMIx |

### Requirements

- Kubernetes 1.27 or later. Device Allocation (DRA) requires 1.33 or later.
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
