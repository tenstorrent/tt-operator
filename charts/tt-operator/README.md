# tt-operator

Umbrella chart for Tenstorrent on Kubernetes. Installs NFD for device labelling, tt-k8s-driver-manager for tt-kmd, firmware, and tt-smi lifecycle, tt-fabric-manager for cluster fabric/interconnect management, tt-dra-driver for DRA-based device scheduling, tt-telemetry for device metrics export, jobset for multi-job workloads, and kubepmix for PMIx-aware MPI scheduling.

<!--
  GENERATED FILE — do not edit by hand.
  Produced by helm-docs from Chart.yaml and values.yaml. To update: edit the
  `# --` annotations in values.yaml (or the dependencies in Chart.yaml), then
  run `make docs` and commit the result. CI (validate.yaml → docs-coherence)
  fails if this file is stale. Note: because the Requirements table below lists
  subchart versions, bumping any dependency in Chart.yaml requires a `make docs`
  refresh too. Install / upgrade / dev docs live in the repo-root README.md,
  maintained separately.
-->

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://kubernetes-sigs.github.io/node-feature-discovery/charts | node-feature-discovery | 0.18.3 |
| oci://ghcr.io/tenstorrent/helm | tt-dra-driver | 0.0.48 |
| oci://ghcr.io/tenstorrent/helm | tt-fabric-manager | 0.2.28 |
| oci://ghcr.io/tenstorrent/helm | tt-k8s-driver-manager | 0.0.6 |
| oci://ghcr.io/tenstorrent/helm | tt-telemetry | 0.2.0 |
| oci://registry.k8s.io/jobset/charts | jobset | 0.12.0 |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| jobset.enabled | bool | `true` | Install JobSet (kubernetes-sigs/jobset) for grouped multi-node Job lifecycle. No external prereqs. |
| kubepmix.enabled | bool | `true` | Install the kubepmix mutating webhook (injects PMIx env into multi-node training Jobs). Requires cert-manager pre-installed. |
| kubepmix.namespace | string | `"kube-pmix"` | Namespace for the kubepmix webhook resources. Defaults to a dedicated kube-pmix namespace; set to your release namespace to consolidate. |
| node-feature-discovery.enabled | bool | `true` | Install node-feature-discovery so Tenstorrent nodes get the feature.node.kubernetes.io/pci-1200_1e52.present label. |
| node-feature-discovery.worker.config.core.featureSources | list | `["pci"]` | NFD feature sources to enable. Restricted to PCI — the only source needed to detect Tenstorrent devices. |
| node-feature-discovery.worker.config.core.labelSources | list | `["pci"]` | NFD label sources to enable. Restricted to PCI to avoid the CPU/memory cost and label clutter of the full source set. |
| node-feature-discovery.worker.tolerations | list | `[{"operator":"Exists"}]` | Tolerations for the NFD worker DaemonSet. Defaults to universal so the PCI label reaches tainted node pools. |
| tt-dra-driver.enabled | bool | `true` | Install tt-dra-driver (DRA kubelet plugin publishing devices as ResourceSlices). Requires k8s 1.33+, tt-fabric-manager.enabled, and the DynamicResourceAllocation feature gate. |
| tt-dra-driver.kubeletPlugin.fabricManagerAgentAddress | string | `"tt-fabric-manager-agent.tt-operator-system.svc.cluster.local:50053"` | Address of the in-cluster TTFM agent Service the DRA plugin calls for GetTopology. |
| tt-fabric-manager.enabled | bool | `true` | Install tt-fabric-manager (TTFM): inter-card/inter-host fabric topology + GetTopology gRPC. Opt-in; most single-node / non-Galaxy setups don't need it. |
| tt-fabric-manager.fullnameOverride | string | `"tt-fabric-manager"` | Drop the release prefix so TTFM Service names render as tt-fabric-manager-{controller,agent}. |
| tt-k8s-driver-manager.enabled | bool | `true` | Install tt-k8s-driver-manager (controllers, CRDs, and per-node images for tt-kmd, firmware flashing, and tt-smi). Disable to manage drivers yourself. |
| tt-telemetry.daemonset | object | `{"affinity":{"nodeAffinity":{"requiredDuringSchedulingIgnoredDuringExecution":{"nodeSelectorTerms":[{"matchExpressions":[{"key":"feature.node.kubernetes.io/pci-1200_1e52.present","operator":"In","values":["true"]},{"key":"tenstorrent.com/deploy.tt-telemetry","operator":"NotIn","values":["false"]}]}]}}}}` | Collector DaemonSet nodeAffinity — schedule on TT-equipped nodes and honor the tenstorrent.com/deploy.tt-telemetry drain gate. |
| tt-telemetry.enabled | bool | `true` | Install tt-telemetry (device telemetry → Prometheus endpoint + web GUI). Alpha software. |
| tt-telemetry.image.repository | string | `"ghcr.io/tenstorrent/tt-telemetry"` | tt-telemetry image repository, pinned to the published org-namespace image. |
| tt-telemetry.image.tag | string | `"0.2.0"` | tt-telemetry image tag. Keep in lockstep with the tt-telemetry subchart version in Chart.yaml. |
| tt-telemetry.namespace | string | `"tt-operator-system"` | Namespace for tt-telemetry resources. The subchart hardcodes this (no Release.Namespace fallback), so match your install namespace. |
