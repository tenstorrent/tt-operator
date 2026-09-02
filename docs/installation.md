# Installation

Before installing, make sure your cluster meets the [Prerequisites](prerequisites.md),
notably cert-manager, and is a [supported platform](platform-support.md).

tt-operator installs into the `tt-operator-system` namespace by default.

## Install

Install the published chart with Helm:

```bash
helm install tt-operator oci://ghcr.io/tenstorrent/helm/tt-operator \
  --namespace tt-operator-system --create-namespace
```

## Verify the install

```bash
# All enabled controller Deployments should become Available.
kubectl -n tt-operator-system get deploy

# NFD should label nodes that have a Tenstorrent device.
kubectl get nodes -l feature.node.kubernetes.io/pci-1200_1e52.present=true
```

No pod should be stuck in `ImagePullBackOff`. If one is, see
[Troubleshooting](troubleshooting.md).

## Common install variations

### Enable or disable components

Every component is a subchart gated by `<name>.enabled`. Install only what you
need by disabling the rest. For example, NFD and the Driver Manager only:

```bash
helm install tt-operator oci://ghcr.io/tenstorrent/helm/tt-operator \
  --namespace tt-operator-system --create-namespace \
  --set tt-fabric-manager.enabled=false \
  --set tt-dra-driver.enabled=false \
  --set tt-telemetry.enabled=false \
  --set jobset.enabled=false \
  --set kubepmix.enabled=false
```

The component keys are `node-feature-discovery`, `tt-k8s-driver-manager`,
`tt-fabric-manager`, `tt-dra-driver`, `tt-telemetry`, `jobset`, and `kubepmix`.

### Use pre-installed drivers

If you manage `tt-kmd` yourself, outside Kubernetes, disable the Driver Manager.
The rest of the stack still runs and uses the already-loaded driver:

```bash
helm install tt-operator oci://ghcr.io/tenstorrent/helm/tt-operator \
  --namespace tt-operator-system --create-namespace \
  --set tt-k8s-driver-manager.enabled=false
```

No Driver Manager controller or installer DaemonSet is created, and the driver
policy resources are not installed.

### Pin component images

Image overrides use the standard repository and tag fields. There is no single
combined image reference key. To pin a build of the Driver Manager:

```bash
helm upgrade tt-operator oci://ghcr.io/tenstorrent/helm/tt-operator \
  --namespace tt-operator-system \
  --set tt-k8s-driver-manager.controller.image.repository=ghcr.io/tenstorrent/tt-k8s-driver-manager \
  --set tt-k8s-driver-manager.controller.image.tag=<tag> \
  --set tt-k8s-driver-manager.driver.image.repository=ghcr.io/tenstorrent/tt-k8s-driver-manager-builder \
  --set tt-k8s-driver-manager.driver.image.tag=<tag> \
  --set tt-k8s-driver-manager.flasher.image.repository=ghcr.io/tenstorrent/tt-k8s-driver-manager-flasher \
  --set tt-k8s-driver-manager.flasher.image.tag=<tag>
```

`controller.image.*` sets the controller Deployment image directly. The
`driver.*` and `flasher.*` images are passed to the controller as the per-node
builder and flasher images it spawns. See the
[Configuration reference](configuration.md) for every overridable value.

### Install into a different namespace

tt-telemetry sets its namespace explicitly. If you install into a namespace other
than `tt-operator-system`, set it to match:

```bash
helm install tt-operator oci://ghcr.io/tenstorrent/helm/tt-operator \
  --namespace my-ns --create-namespace \
  --set tt-telemetry.namespace=my-ns
```
