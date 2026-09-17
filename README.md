# tt-operator

## Overview

tt-operator is the umbrella Helm chart for running Tenstorrent workloads on
Kubernetes. It packages the individual cluster components as subcharts so a
cluster administrator can install, upgrade, and configure the whole stack with
one Helm release. It installs:

- **[node-feature-discovery](https://github.com/kubernetes-sigs/node-feature-discovery)** (NFD):
  stamps `feature.node.kubernetes.io/pci-1200_1e52.present=true` on
  every node that has a Tenstorrent PCI device.
- **[tt-k8s-driver-manager](https://github.com/tenstorrent/tt-k8s-driver-manager)**:
  controllers, custom resource definitions (CRDs), and images that own the
  lifecycle of the `tt-kmd` kernel module, device firmware, and `tt-smi` on
  each node.
- **[tt-fabric-manager](https://docs.tenstorrent.com/tt-fabric-manager/)**:
  per-node agent and cluster controller for inter-card and inter-host
  fabric topology.
- **[tt-dra-driver](https://github.com/tenstorrent/tt-dra-driver)**:
  Dynamic Resource Allocation (DRA) kubelet plugin that publishes Tenstorrent
  devices as `ResourceSlices`. Requires Kubernetes 1.33 or later with the DRA
  feature gate, and `tt-fabric-manager` enabled.
- **[tt-telemetry](https://github.com/tenstorrent/tt-telemetry)**:
  collects device telemetry and exports a Prometheus endpoint plus a
  simple web interface.
- **[JobSet](https://github.com/kubernetes-sigs/jobset)**:
  groups related Jobs into a single managed unit for multi-node
  training workloads.
- **kubepmix**: mutating webhook that injects Process Management Interface
  for Exascale (PMIx) environment variables into multi-node training Jobs.

Each subchart can be turned off with `<name>.enabled=false` at install
time. The controllers and per-node images live in their respective
component repositories; this repository is only the deployment surface.
Full documentation is published at <https://docs.tenstorrent.com/tt-operator/>.

## Prerequisites

- **cert-manager** must be installed on the cluster before installing
  tt-operator. The bundled `kubepmix` mutating webhook is issued a TLS
  cert via cert-manager `Issuer` + `Certificate` resources, so
  `helm install` fails without it.

  ```bash
  kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml
  ```

  If you don't need kubepmix, disable it with `--set kubepmix.enabled=false`
  to skip the cert-manager dependency.

## Getting started

```bash
helm repo add node-feature-discovery https://kubernetes-sigs.github.io/node-feature-discovery/charts
helm repo update
helm dependency build charts/tt-operator

helm upgrade --install tt-operator charts/tt-operator \
  --namespace tt-operator-system --create-namespace
```

Or install the chart published to the GitHub Container Registry as an OCI
artifact, which needs no checkout:

```bash
helm install tt-operator oci://ghcr.io/tenstorrent/helm/tt-operator \
  --namespace tt-operator-system --create-namespace
```

## Upgrades

Helm applies subchart `crds/` directories on `helm install` only. `helm
upgrade` deliberately skips them, a Helm 3 convention that prevents the
chart from silently widening or narrowing the CRD schema under live
custom resources. When bumping a subchart whose `crds/` schema changed,
re-apply its CRDs by hand before the upgrade:

```bash
helm pull oci://ghcr.io/tenstorrent/helm/tt-operator --version <new> --untar -d /tmp/tt-operator-pull
kubectl apply --server-side --force-conflicts -f /tmp/tt-operator-pull/tt-operator/charts/<subchart>/crds/
helm upgrade tt-operator oci://ghcr.io/tenstorrent/helm/tt-operator --version <new> \
  -n tt-operator-system --reuse-values
```

`--server-side` matches upstream JobSet's documented install (its CRD's
validation schema exceeds the 262144-byte client-side
`last-applied-configuration` annotation limit, so plain
`kubectl apply -f` fails). `--force-conflicts` is needed when
re-applying over a CRD whose fields are already field-managed (e.g. by
a prior Helm install). See
[kubernetes-sigs/jobset README](https://github.com/kubernetes-sigs/jobset#installation).

## Pinning subchart images

The umbrella forwards image overrides to each subchart via its values block.
Images use the standard `{ repository, tag }` split; there is no single
`image=<ref>` string key. To pin a feature-branch build of the driver manager:

```bash
helm upgrade tt-operator charts/tt-operator \
  --set tt-k8s-driver-manager.controller.image.repository=ghcr.io/tenstorrent/tt-k8s-driver-manager \
  --set tt-k8s-driver-manager.controller.image.tag=<tag> \
  --set tt-k8s-driver-manager.driver.image.repository=ghcr.io/tenstorrent/tt-k8s-driver-manager-builder \
  --set tt-k8s-driver-manager.driver.image.tag=<tag> \
  --set tt-k8s-driver-manager.flasher.image.repository=ghcr.io/tenstorrent/tt-k8s-driver-manager-flasher \
  --set tt-k8s-driver-manager.flasher.image.tag=<tag>
```

`controller.image.*` sets the controller Deployment image directly; the
`driver.*` and `flasher.*` images are passed to the controller as the
`DRIVER_IMAGE` / `FLASHER_IMAGE` env vars (the per-node builder/flasher pods it
spawns), not as separate workloads. Other subcharts follow the same pattern,
e.g. tt-telemetry:

```bash
helm upgrade tt-operator charts/tt-operator \
  --set tt-telemetry.image.repository=ghcr.io/tenstorrent/tt-telemetry \
  --set tt-telemetry.image.tag=<tag>
```

The `image-pin-forwarding` job in the `static-checks` workflow renders the
chart with these overrides and asserts they reach the rendered pod specs, so
this stays honest.

## Development cluster (kind)

```bash
make kind-up
make helm-install
kubectl apply -f hack/dev/label-fake-tt-nodes.yaml
```

`label-fake-tt-nodes.yaml` stamps the NFD label on kind workers so the
driver-manager controllers will reconcile them without real hardware.

## Contributing

Contributions are welcome. Report bugs and request features through
[GitHub Issues](https://github.com/tenstorrent/tt-operator/issues), and submit
bug fixes and new functionality as pull requests. Pull requests are reviewed
weekly. See [CONTRIBUTING.md](CONTRIBUTING.md) for the development workflow
and requirements, and [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) for community
expectations. To report a security vulnerability, follow
[SECURITY.md](SECURITY.md).

## License

- [LICENSE](LICENSE): Apache License 2.0, the overall license for this project,
  except where specified.
- [LICENSE-DOCS](LICENSE-DOCS): Creative Commons Attribution 4.0 International,
  the license for all documentation and images only.
- [LICENSE_understanding.txt](LICENSE_understanding.txt): Tenstorrent's
  clarification of how the Apache License 2.0 applies to this project.
- [NOTICE](NOTICE): copyright notice and third-party attributions.
