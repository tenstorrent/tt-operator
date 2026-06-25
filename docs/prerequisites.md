# Prerequisites

Have these in place before [installing](installation.md).

## cert-manager

The bundled PMIx admission webhook (`kubepmix`) is issued a TLS certificate via
cert-manager `Issuer` and `Certificate` resources, so **`helm install` fails if
cert-manager is not present**. Install it first:

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml
```

If you do not need `kubepmix`, you can skip cert-manager by disabling it:

```bash
--set kubepmix.enabled=false
```

## Kubernetes version

- 1.27 or later for the core stack.
- 1.33 or later if you use the Dynamic Resource Allocation driver *(beta)*, which
  relies on the `DynamicResourceAllocation` feature being available on the API
  server and kubelet.

## Registry access

The component images are hosted on GitHub Container Registry (`ghcr.io`). Nodes
must be able to pull from it, directly or through your mirror or pull secret.
Pods stuck in `ImagePullBackOff` almost always indicate a registry-access gap.
See [Troubleshooting](troubleshooting.md).

## Host requirements for the driver

The driver manager builds `tt-kmd` against the running kernel on each target
node, so nodes must have the matching kernel headers available. See the
[Driver manager](components/driver-manager.md) component page.
