# Multi-node scheduling (JobSet + PMIx)

**Status: Beta** — installed by default and usable for evaluation; some
capabilities are still maturing and may change.

Two components support multi-node jobs on Tenstorrent hardware:

- **JobSet** ([kubernetes-sigs/jobset](https://github.com/kubernetes-sigs/jobset))
  groups related Jobs into a single managed unit, so a multi-node run is created,
  scheduled, and cleaned up as one object.
- **kubepmix** is a mutating admission webhook that injects PMIx environment
  variables into participating Jobs/pods, wiring up the process management
  interface multi-node ranks use to find each other.

## Prerequisite

kubepmix's webhook is served over TLS issued by **cert-manager**, so cert-manager
must be installed before tt-operator (see [Prerequisites](../prerequisites.md)).
The webhook resources are created in the `kube-pmix` namespace by default
(`kubepmix.namespace`).

## Opting a Job in

The webhook only mutates resources that carry the opt-in label, so it has no
effect on unrelated workloads. Label the pods that should receive PMIx wiring:

```yaml
metadata:
  labels:
    kubepmix.dev/enabled: "true"
```

## Verify

```bash
kubectl get crd jobsets.jobset.x-k8s.io
kubectl -n kube-pmix get deploy kube-pmix
kubectl get mutatingwebhookconfiguration kube-pmix
```

```{note}
The components and webhook wiring are available now; running a real co-scheduled
multi-node job end-to-end is maturing. To install without them, set
`--set jobset.enabled=false` and `--set kubepmix.enabled=false`.
```
