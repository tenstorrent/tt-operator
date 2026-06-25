# Release notes

## tt-operator v0.1

The first release of the Tenstorrent Operator. tt-operator packages the
components needed to run Tenstorrent accelerators under Kubernetes into a single
umbrella Helm chart and validates them end-to-end on real Tenstorrent hardware.

### Highlights

- **One-step install** of the full stack via Helm, from a checkout or directly
  from the published OCI chart.
- **Device discovery** — Tenstorrent nodes are automatically labeled so
  workloads and operands schedule only where devices are present.
- **Driver lifecycle** — install, version-upgrade, and node-scope the `tt-kmd`
  kernel driver declaratively with the `TenstorrentDriverPolicy` resource,
  including cordon/drain and telemetry quiesce during an upgrade.
- **Firmware flashing** via the `TenstorrentFirmwarePolicy` resource.
- **Telemetry** — a Prometheus `/metrics` endpoint reporting per-device health,
  with topology-aware identity labels.
- **Day-2 operations** — in-place `helm upgrade` and clean `helm uninstall`.

### Supported features

| Capability | Resource / surface |
|---|---|
| Device labeling | Node Feature Discovery PCI label |
| Driver install / upgrade / scoping | `TenstorrentDriverPolicy` |
| Firmware flashing | `TenstorrentFirmwarePolicy` |
| Telemetry | Prometheus `/metrics` |

### Beta features

The following components are installed by default and available for evaluation.
Their core behavior works today; some capabilities are still maturing and may
change.

- **Fabric manager** — inter-card / inter-host topology resolution.
- **Device allocation (DRA)** — publishing devices as schedulable resources via
  Kubernetes Dynamic Resource Allocation.
- **Multi-node scheduling** — JobSet plus PMIx environment injection for
  multi-node jobs.

### Requirements

- Kubernetes **1.27+** (the Dynamic Resource Allocation beta features require
  **1.33+**).
- **cert-manager** installed on the cluster (required by the bundled PMIx
  admission webhook; see [Prerequisites](prerequisites.md)).
- Network access to the container registry hosting the Tenstorrent images.

See [Platform support](platform-support.md) for the validated devices and
environments.

### Known limitations

- **Device allocation (DRA)** requires resolvable fabric topology on the node;
  on systems without staged topology, devices are not yet published as
  schedulable resources.
- **Air-gapped / private-registry installs** are not yet covered by a documented
  workflow.
- The deep, per-feature capabilities of the **beta** components above are not
  yet part of the supported surface.
