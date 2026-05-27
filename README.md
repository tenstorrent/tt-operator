# tt-operator

Umbrella Helm chart for running Tenstorrent workloads on Kubernetes. Installs:

- **[node-feature-discovery](https://github.com/kubernetes-sigs/node-feature-discovery)** —
  stamps `feature.node.kubernetes.io/pci-1200_1e52.present=true` on
  every node that has a Tenstorrent PCI device.
- **[tt-k8s-driver-manager](https://github.com/tenstorrent/tt-k8s-driver-manager)** —
  controllers, CRDs, and images that own the lifecycle of `tt-kmd`,
  device firmware, and `tt-smi` on each node.
- **[tt-fabric-manager](https://github.com/tenstorrent/tt-fabric-manager)** —
  per-node agent + cluster controller for inter-card / inter-host
  fabric topology.
- **[tt-dra-driver](https://github.com/tenstorrent/tt-dra-driver)** —
  DRA kubelet plugin that publishes Tenstorrent devices as
  `ResourceSlices` (requires k8s 1.33+ with the DRA feature gate, and
  `tt-fabric-manager` enabled).
- **[tt-telemetry](https://github.com/tenstorrent/tt-telemetry)** —
  collects device telemetry and exports a Prometheus endpoint plus a
  simple web GUI.
- **[JobSet](https://github.com/kubernetes-sigs/jobset)** —
  groups related Jobs into a single managed unit for multi-node
  training workloads.
- **kubepmix** — mutating webhook that injects PMIx env vars into
  multi-node training Jobs.

Each subchart can be turned off via `<name>.enabled=false` at install
time. The controllers and per-node images live in their respective
component repos; this repo is just the deployment surface.

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

## Install

```bash
helm repo add node-feature-discovery https://kubernetes-sigs.github.io/node-feature-discovery/charts
helm repo update
helm dependency build charts/tt-operator

helm upgrade --install tt-operator charts/tt-operator \
  --namespace tt-operator-system --create-namespace
```

Or via the OCI-published chart (no checkout required):

```bash
helm install tt-operator oci://ghcr.io/tenstorrent/helm-charts/tt-operator \
  --namespace tt-operator-system --create-namespace
```

## Pinning subchart images

The umbrella forwards image overrides to `tt-k8s-driver-manager` via the
`tt-k8s-driver-manager.*` block in `values.yaml`. To pin a feature-branch
build of the driver manager:

```bash
helm upgrade tt-operator charts/tt-operator \
  --set tt-k8s-driver-manager.controller.image=ghcr.io/tenstorrent/tt-k8s-driver-manager-controller:<tag> \
  --set tt-k8s-driver-manager.driver.image=ghcr.io/tenstorrent/tt-k8s-driver-manager-builder:<tag> \
  --set tt-k8s-driver-manager.flasher.image=ghcr.io/tenstorrent/tt-k8s-driver-manager-flasher:<tag>
```

## Dev cluster (kind)

```bash
make kind-up
make helm-install
kubectl apply -f hack/dev/label-fake-tt-nodes.yaml
```

`label-fake-tt-nodes.yaml` stamps the NFD label on kind workers so the
driver-manager controllers will reconcile them without real hardware.
