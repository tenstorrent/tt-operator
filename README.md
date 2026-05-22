# tt-operator

Umbrella Helm chart for running Tenstorrent workloads on Kubernetes.
Pulls in four subcharts, each opt-in or opt-out via a `<name>.enabled`
toggle in `values.yaml`:

| Subchart | Default | What it does |
|---|---|---|
| [node-feature-discovery](https://github.com/kubernetes-sigs/node-feature-discovery) | enabled | Stamps `feature.node.kubernetes.io/pci-1200_1e52.present=true` on Tenstorrent nodes. |
| [tt-k8s-driver-manager](https://github.com/tenstorrent/tt-k8s-driver-manager) | enabled | Controllers + CRDs + images for tt-kmd, device firmware, and tt-smi lifecycle. |
| [tt-fabric-manager](https://github.com/tenstorrent/tt-fabric-manager) | **disabled** | Per-node agent + cluster controller for multi-card / multi-host fabric topology. Required by tt-dra-driver. |
| [tt-dra-driver](https://github.com/tenstorrent/tt-dra-driver) | **disabled, staged**\* | Dynamic Resource Allocation driver advertising Tenstorrent ASICs through the k8s 1.33+ DRA API. |

\* The DRA chart dep is commented out in `Chart.yaml` until upstream
publishes a release to `oci://ghcr.io/tenstorrent/helm/`; the values
block in `values.yaml` is ready, so enabling it once the chart ships
is a two-line uncomment + bump.

This repo is just the deployment surface — every controller, image,
and CRD lives in the upstream subchart repos.

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
