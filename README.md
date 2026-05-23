# tt-operator

Umbrella Helm chart for running Tenstorrent workloads on Kubernetes. Installs:

- **node-feature-discovery** — stamps `feature.node.kubernetes.io/pci-1200_1e52.present=true`
  on every node that has a Tenstorrent PCI device.
- **[tt-k8s-driver-manager](https://github.com/tenstorrent/tt-k8s-driver-manager)** —
  controllers, CRDs, and images that own the lifecycle of `tt-kmd`,
  device firmware, and `tt-smi` on each node.

The controllers and per-node images live in `tt-k8s-driver-manager`; this
repo is just the deployment surface.

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
  --set tt-k8s-driver-manager.driver.image=ghcr.io/tenstorrent/tt-k8s-driver-manager-installer:<tag> \
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
