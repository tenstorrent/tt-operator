# aus2-dev2 deploy + firmware-flash validation log

End-to-end deploy of this branch of `tt-operator` to the `aus2-dev2` RKE2
cluster (3 nodes: e01cs01 control-plane, e01cs02 + e01cs03 workers, k8s
1.34, each node carrying 8 Wormhole n150 cards). Captures all commands
run, manifests applied, and the firmware-flash validation results.

## Pre-flight (2026-05-14)

| | |
|---|---|
| Cluster | `aus2-dev2` (RKE2, k8s 1.34, 3 nodes) |
| Cards | 8 × Wormhole n150 per node (pci `1e52:401e`, class 12) |
| Branch | `kluong/sw-operator` |
| Final commit | `795ab70` (after dkms regex fix) |
| Image tag scheme | `ghcr.io/tenstorrent/<image>:sha-<7chars>` (immutable per commit) |

```bash
export KUBECONFIG=$HOME/.kube/aus2-dev2.yaml
kubectl get nodes -o wide   # → 3 Ready
```

## 1. Image visibility (one-time per org)

GHCR images default to **private** when first pushed. The Tenstorrent org
also enforces **SAML SSO**, so even an org member's classic PAT needs to
be SAML-authorized for the org before pulls succeed.

For this deploy we used a classic PAT with `read:packages`, SAML-authorized
for tenstorrent, stored in a `docker-registry` Secret in the namespace and
attached to the controller + default ServiceAccounts:

```bash
kubectl -n tt-operator-system create secret docker-registry ghcr-pull \
  --docker-server=ghcr.io \
  --docker-username=<gh-user> \
  --docker-password="$GHCR_PAT" \
  --dry-run=client -o yaml | kubectl apply -f -

kubectl -n tt-operator-system patch sa tt-operator-controller \
  -p '{"imagePullSecrets":[{"name":"ghcr-pull"}]}'
kubectl -n tt-operator-system patch sa default \
  -p '{"imagePullSecrets":[{"name":"ghcr-pull"}]}'
```

Going forward, the cleaner option is making the GHCR packages public
(`https://github.com/orgs/tenstorrent/packages/container/<name>/settings`
→ Change visibility → Public). Removes the token-rotation problem entirely.

## 2. Install the operator + NFD

```bash
helm repo add node-feature-discovery \
  https://kubernetes-sigs.github.io/node-feature-discovery/charts
helm repo update
helm dependency build charts/tt-operator

SHA=sha-795ab70

helm upgrade --install tt-operator ./charts/tt-operator \
  --namespace tt-operator-system --create-namespace \
  --set controller.image=ghcr.io/tenstorrent/tt-operator:$SHA \
  --set flasher.image=ghcr.io/tenstorrent/tt-fw-flasher:$SHA \
  --set driver.image=ghcr.io/tenstorrent/tt-kmd-installer:$SHA \
  --wait --timeout=2m
```

What gets installed:
- CRDs `tenstorrentfirmwarepolicies.firmware.tenstorrent.com`
  and `tenstorrentdriverpolicies.driver.tenstorrent.com`
- `tt-operator-controller` Deployment + ServiceAccount + ClusterRole
- NFD master + worker DaemonSet + gc (chart dependency), restricted via
  `node-feature-discovery.worker.config.core.{feature,label}Sources: [pci]`
  so nodes only get PCI presence labels — no noise.

Verify NFD labeled the nodes:

```bash
kubectl get nodes -L feature.node.kubernetes.io/pci-1200_1e52.present
# all 3 should show `true`
```

## 3. Install tt-kmd on the workers

Without the kernel module, `/dev/tenstorrent/` doesn't exist and the
flasher pod fails fast with "No Tenstorrent driver detected!". Apply a
`TenstorrentDriverPolicy` to have the operator manage tt-kmd:

```yaml
# hack/dev/aus2-dev2/driver-policy.yaml
apiVersion: driver.tenstorrent.com/v1alpha1
kind: TenstorrentDriverPolicy
metadata:
  name: aus2-dev2-default
spec:
  version: "2.8.0"
  nodeSelector: {}   # AND'd with NFD pci label
```

```bash
kubectl apply -f hack/dev/aus2-dev2/driver-policy.yaml
kubectl get ttdp
```

The controller creates a privileged DaemonSet (`ttdrv-aus2-dev2-default`)
that runs an installer pod per labeled node. Each pod:
1. `apt install dkms linux-headers-$(uname -r) git` (on the host via nsenter)
2. `git clone tt-kmd@ttkmd-2.8.0`
3. `dkms add . && dkms install tenstorrent/2.8.0 -k $(uname -r)`
4. `modprobe tenstorrent`
5. Verifies + idles

Watch logs:

```bash
kubectl -n tt-operator-system logs -f -l driver.tenstorrent.com/cr=aus2-dev2-default | grep tt-kmd-installer
```

Expected end state for each pod:

```
[tt-kmd-installer] tt-kmd 2.8.0 installed successfully; idling
```

## 4. Flash firmware — initial old version

Apply [`policy-old-19.8.1.yaml`](policy-old-19.8.1.yaml) targeting a
single worker (`e01cs03`) to keep observability if anything goes sideways:

```bash
kubectl apply -f hack/dev/aus2-dev2/policy-old-19.8.1.yaml
kubectl get ttfwp -w
```

The controller spawned `ttfwp-aus2-dev2-test-e01cs03-19-8-1-<hash>`. Logs
from the Job pod (`kubectl -n tt-operator-system logs -l firmware.tenstorrent.com/cr=aus2-dev2-test`):

```
[flasher] pre-flash: tt-smi -s
[flasher] pre-flash versions: 18.8.0.0 18.8.0.0 ... 18.9.0.0
[flasher] flash: tt-flash --no-color flash --fw-tar /work/bundle.fwbundle
... Sub Stage FLASH Step 1: Wormhole[0] ...
    Detected major version upgrade from (18, 8, 0, 0) to (19, 8, 1, 0)
    Writing new firmware... SUCCESS
... (repeated for all 8 cards) ...
Stage: RESET
... Reset successfully completed for device at PCI index 0..7
FLASH SUCCESS
[flasher] post-flash: tt-smi -s
[flasher] post-flash versions: 19.8.1.0 19.8.1.0 19.8.1.0 19.8.1.0 19.8.1.0 19.8.1.0 19.8.1.0 19.8.1.0
[flasher] flash succeeded: all devices at 19.8.1.0
```

Result: **8/8 cards flashed from mixed 18.x → 19.8.1.0 in 40 seconds**.
Job exit 0, CR `UPTODATE=1`.

## 5. Flash firmware — upgrade to new version

```bash
kubectl patch ttfwp aus2-dev2-test --type=merge \
  -p '{"spec":{"version":"19.9.0"}}'
```

Controller spawned `ttfwp-aus2-dev2-test-e01cs03-19-9-0-<hash>` (different
hash because version is in the Job-name digest). Logs:

```
[flasher] pre-flash versions: 19.8.1.0 19.8.1.0 ... (all 8 at 19.8.1.0)
... Detected minor version upgrade from (19, 8, 1, 0) to (19, 9, 0, 0)
... Writing new firmware... SUCCESS  (×8)
... FLASH SUCCESS
[flasher] post-flash versions: 19.9.0.0 19.9.0.0 19.9.0.0 19.9.0.0 19.9.0.0 19.9.0.0 19.9.0.0 19.9.0.0
[flasher] flash succeeded: all devices at 19.9.0.0
```

Result: **8/8 cards upgraded 19.8.1.0 → 19.9.0.0 in 34 seconds**.
CR `UPTODATE=1`, `VERSION=19.9.0`.

## Issues encountered + fixes

| Problem | Root cause | Fix (commit) |
|---|---|---|
| GHCR 401 then 403 | Packages private; PAT lacked SAML-SSO authorization for org | User SAML-authorized PAT |
| Helm `templates/crd.yaml` collided with `crds/` | Both tried to install the CRD; chart-managed needs Helm labels, `crds/` writes without them | Dropped `templates/crd.yaml`; only `crds/` (`9e430d0`) |
| QEMU arm64 cross-build took 13+ min, flasher failed | Python wheel compile under QEMU emulation flaky + slow | amd64-only matrix (`9cd0ebc`) |
| Helm CI `helm dependency build` errored | NFD repo wasn't registered | Added `helm repo add` step (`9cd0ebc`) |
| Driver pod OOM-killed mid-DKMS-compile | Original chart-shipped DS had `memory: 256Mi`; dkms compilation hits the cgroup limit | Switched to controller-managed DS (no memory limit by default) (`7c94fbc`) |
| Driver pod CrashLoopBackoff: `DKMS tree already contains tenstorrent-2.8.0` | Cleanup regex required a `,` after version; the "added" state has `:` instead | Permissive regex + idempotent `dkms add` (`795ab70`) |
| First flasher failure logged `stderr: ` (empty) | tt-smi puts real errors on stdout, but the script only printed stderr on failure | Dump both streams + exit code (`b3c8c69`) |

## 6. Driver downgrade + upgrade validation

After porting the driver installer from bash to Go (`sha-4a945c5`), the
DaemonSet was re-rolled. Cycle:

```bash
# Downgrade
kubectl patch ttdp aus2-dev2-default --type=merge -p '{"spec":{"version":"2.7.0"}}'
# … wait ~17s …
kubectl get ttdp                              # VERSION 2.7.0, READY 3
kubectl -n tt-operator-system logs <pod>      # see step 1/4 → step 4/4

# Upgrade back
kubectl patch ttdp aus2-dev2-default --type=merge -p '{"spec":{"version":"2.8.0"}}'
# … wait ~15s …
kubectl get ttdp                              # VERSION 2.8.0, READY 3
```

Sample install log (downgrade):

```
I0514 22:02:37 main.go:90] step 1/4: install dkms + linux-headers + git on host
I0514 22:02:45 main.go:100] step 2/4: clone tt-kmd at ttkmd-2.7.0
I0514 22:02:46 main.go:109] step 3/4: dkms cleanup + add + install + modprobe
I0514 22:02:46 main.go:124] removing existing dkms entry tenstorrent/2.8.0
I0514 22:02:54 main.go:149] step 4/4: verify
I0514 22:02:54 main.go:75]  tt-kmd 2.7.0 installed and verified; idling
```

Both directions exercised the DKMS cleanup path correctly — the parser
identified the existing entry (`2.8.0: added` format on first try,
standard installed format thereafter) and `dkms remove` cleanly cleared
it before `dkms install` of the new version. The bash regex bug from
the first iteration is now covered by a unit test in
`internal/dkms/parse_test.go`.

## 7. Driver-install honesty test (2026-05-15)

Followup test: validate what happens to the kmd install path when a
userspace process is genuinely holding `/dev/tenstorrent/0` (refcnt > 0).
Earlier driver tests had used a busybox `sleep` with the device mounted
as hostPath, which doesn't actually `open()` any device files — so the
"module in use" failure mode was never exercised.

Test setup: a deliberate device-holder workload that keeps an fd against
the device:

```yaml
# hack/dev/aus2-dev2/device-holder.yaml
command: ["sh", "-c", "exec sleep 99999 < /dev/tenstorrent/0"]
```

`exec sleep < /dev/tenstorrent/0` opens the device on the shell's fd 0,
then exec replaces the shell with sleep (fd 0 stays open). Verified via
`fuser /dev/tenstorrent/0` → PID present, and
`/sys/module/tenstorrent/refcnt` → 1.

**Findings (two bugs, both now fixed):**

1. **Silent corruption in `loadedVersion()`**. The Go installer was
   reading the kmd version with `modinfo tenstorrent` — which reads the
   `.ko` file's metadata, not what's running in the kernel. After a
   failed `modprobe -r` (held module), `dkms install` overwrote the file
   on disk with the new version while the old version stayed loaded.
   Verify saw "new version on disk" and reported success. Cluster state:
   kernel running 2.8.0, file says 2.7.0, CR status says READY 3 —
   a three-way disagreement that wasn't detectable from `kubectl tt driver`.

   Fix: read from `/sys/module/<name>/version` (the running kernel's
   view, ground truth). Also check `/sys/module/<name>/refcnt` *before*
   attempting modprobe -r so we can surface "module in use" as a hard
   failure with the holder PIDs, instead of swallowing it via `|| true`.
   Commit `300b653`.

2. **`TenstorrentDriverPolicy.status.summary.failed` was always 0**. The
   previous formula did `NumberUnavailable - (Desired - Ready)`, which
   double-counted the gap and zeroed out for any single-pod failure. So
   the CR reported READY 2 / FAILED 0 even with one pod CrashLooping —
   you had to look at the pod directly to know things were broken.

   Fix: `Failed = Desired - Available`. Single-pod CrashLoop now
   correctly shows READY 2 / FAILED 1. Commit `3e0add8`.

**Validation after the fix:** with the device-holder pod still running
and the new image deployed, applying a version change produced:

```
F0515 22:54:49 main.go:66] install failed: tt-kmd 2.8.0 is loaded with
  refcnt=1; cannot reinstall while in use. Holders: /dev/tenstorrent/0:
  1265060. Cordon + drain pods holding /dev/tenstorrent and retry.
```

The pod CrashLoops; CR shows READY 2 / FAILED 1 honestly. Once the
holder is deleted, the pod's next retry runs to completion (refcnt=0,
unload OK, install OK, modprobe OK, kernel-loaded version matches
desired).

## 8. Readiness probe + version-label honesty test (2026-05-18)

Two coordinated changes deployed: a readinessProbe on the driver
DaemonSet pod (execs `nsenter -t 1 -m -u -- cat
/sys/module/tenstorrent/version | grep -qFx "$TT_KMD_VERSION"`), and a
controller-side sync that writes
`driver.tenstorrent.com/kmd-version=<version>` on a node when its
installer pod is Ready, removes it when NotReady.

**Initial bug surfaced during validation.** First version of the sync
wrote `cr.Spec.Version` onto nodes whose pods were the OLD pre-rollout
pods (still passing their own readiness against the OLD kernel
version). At the instant the spec flipped, labels would jump to the
new version even though the rollout hadn't reached those nodes yet.

Fix: read the version from each running pod's `TT_KMD_VERSION` env
var (the source of truth for "what version is this pod's probe
checking against") instead of `cr.Spec.Version`. Commit `0fe975c`.

**Live validation after the fix.** Patched
`spec.version: 2.8.0 → 2.7.0` on a cluster that already had 3 nodes at
2.8.0. Observed every 5 seconds:

| t | e01cs01 | e01cs02 | e01cs03 | observation |
|---|---|---|---|---|
| 0s | 2.8.0 | *(empty)* | 2.8.0 | e01cs02's new pod NotReady → label cleared |
| 17s | 2.8.0 | 2.7.0 | *(empty)* | e01cs02 done; e01cs03 mid-install → cleared |
| 39s | *(empty)* | 2.7.0 | 2.7.0 | e01cs01's turn → cleared |
| end | 2.7.0 | 2.7.0 | 2.7.0 | all converged |

Throughout: `summary.failed=1` while any pod is mid-install (correct),
back to 0 once all Ready. Pod-Ready signal is honest — driven by the
probe reading `/sys/module/tenstorrent/version`, not "container alive."

Three bugs surfaced during this single feature, all variants of "trust
the wrong field":
1. `loadedVersion()` reading the .ko file instead of `/sys/module`
2. `summary.failed` arithmetic always 0
3. Label sync using `cr.Spec.Version` instead of pod env

Pattern: every time the operator conflates *intent* (CR spec) with
*truth* (kernel state), there's a class of bug. Live tests against a
real device-holder workload caught all three.

## Cleanup

```bash
kubectl delete ttfwp aus2-dev2-test
kubectl delete ttdp aus2-dev2-default
helm uninstall -n tt-operator-system tt-operator
# CRDs stay (Helm convention); drop manually if needed:
kubectl delete crd \
  tenstorrentfirmwarepolicies.firmware.tenstorrent.com \
  tenstorrentdriverpolicies.driver.tenstorrent.com
```

## Repo split — standalone tt-k8s-driver-manager validation (2026-05-21)

After splitting tt-operator into:
- `tt-operator` — umbrella chart (NFD + tt-k8s-driver-manager dependency)
- `tt-k8s-driver-manager` — controllers, CRDs, installer/flasher/builder images

Verified the new repo's controller image works against this cluster.
Skipped the umbrella plumbing (subchart isn't published yet); installed
tt-k8s-driver-manager directly.

```bash
# Tear down prod tt-operator (kept CRs + CRDs).
helm -n tt-operator-system uninstall tt-operator
# NFD subchart goes with it — node labels disappear. Reinstall NFD alone:
helm repo add node-feature-discovery https://kubernetes-sigs.github.io/node-feature-discovery/charts
helm -n node-feature-discovery upgrade --install nfd \
  node-feature-discovery/node-feature-discovery --version 0.18.3 --create-namespace \
  --set 'worker.config.core.featureSources={pci}' \
  --set 'worker.config.core.labelSources={pci}'
# Wait for pci-1200_1e52.present=true to come back on all 3 nodes.

# New namespace + copy the ghcr-pull secret over.
kubectl create namespace tt-k8s-driver-manager-system
kubectl -n tt-operator-system get secret ghcr-pull -o yaml \
  | sed 's/namespace: tt-operator-system/namespace: tt-k8s-driver-manager-system/' \
  | kubectl apply -f -
kubectl -n tt-k8s-driver-manager-system patch sa default \
  --type merge -p '{"imagePullSecrets":[{"name":"ghcr-pull"}]}'

# Install from local checkout, pin to the GHA-built branch tag.
TAG=kluong-initial-extraction
helm -n tt-k8s-driver-manager-system upgrade --install tt-k8s-driver-manager \
  ~/tt-k8s-driver-manager/charts/tt-k8s-driver-manager \
  --set controller.image=ghcr.io/tenstorrent/tt-k8s-driver-manager-controller:$TAG \
  --set driver.image=ghcr.io/tenstorrent/tt-k8s-driver-manager-installer:$TAG \
  --set flasher.image=ghcr.io/tenstorrent/tt-k8s-driver-manager-flasher:$TAG
kubectl -n tt-k8s-driver-manager-system patch sa tt-k8s-driver-manager-controller \
  --type merge -p '{"imagePullSecrets":[{"name":"ghcr-pull"}]}'
kubectl -n tt-k8s-driver-manager-system rollout restart deploy tt-k8s-driver-manager-controller
```

Gotcha: helm patches the SA on install but the *first* controller pod is
already scheduled before the patch applies → `ImagePullBackOff`. Need
`rollout restart` (or include `imagePullSecrets` directly on the chart's
Deployment — chart improvement TBD).

### Outcome

| | |
|---|---|
| Controller pod | `tt-k8s-driver-manager-controller-69fc4f4bb4-jk4lg` Ready in ~15s after restart |
| Driver DaemonSet | `ttdrv-aus2-dev2-default` 3/3 ready in ~20s (installer pods all detected tt-kmd 2.7.0 already loaded, idled) |
| `driver.tenstorrent.com/kmd-version=2.7.0` | preserved on all 3 nodes |
| `TenstorrentDriverPolicy aus2-dev2-default` | status flipped to `Ready=True, AllReady` |
| `TenstorrentFirmwarePolicy aus2-dev2-test` | controller re-flashed e01cs03 from 19.9.0→19.9.0 (same version) — 40s Job, succeeded, status returned to `AllUpToDate` |

The unnecessary firmware re-flash is the migration-time gotcha worth
calling out. The firmware controller decides "needs flash?" by checking
for a Complete Job in *its own namespace*; when the controller moves
namespaces, no such Job exists, so it re-runs the flash. The node's
`firmware.tenstorrent.com/current-version=19.9.0.0` annotation already
matched the desired version but isn't part of the decision today. Either
(a) trust the annotation, or (b) trust an idempotent `tt-smi -s` readback
preflight inside the flasher (it already runs; just have it short-circuit
when the readback matches). For 0-downtime ns moves, (a) is needed; for
honest reflash semantics, (b) is enough.

### Leftover state to clean up later

- DaemonSet `ttdrv-aus2-dev2-default` in `tt-operator-system` (0 desired,
  orphaned by `helm uninstall`) — `kubectl delete ds -n tt-operator-system ttdrv-aus2-dev2-default`
  → done.

## Umbrella e2e (2026-05-21)

After the standalone validation, ran the umbrella chart end-to-end. The
subchart needed to be resolvable from an OCI registry:

```bash
# Temporarily expand helm-release.yaml on the new repo's branch:
#   on: push: branches: [main, kluong/initial-extraction]
# (path filter dropped so editing the workflow itself fires). Push → GHA
# publishes oci://ghcr.io/tenstorrent/helm-charts/tt-k8s-driver-manager:0.1.0.
# Revert before merge.

# Local helm needs read:packages auth. Reuse the cluster's ghcr-pull PAT:
AUTH=$(kubectl -n tt-operator-system get secret ghcr-pull -o jsonpath='{.data.\.dockerconfigjson}' \
  | base64 -d | jq -r '.auths["ghcr.io"].auth' | base64 -d)
echo "${AUTH#*:}" | helm registry login ghcr.io --username "${AUTH%%:*}" --password-stdin

# Pull subchart packages.
helm repo add node-feature-discovery https://kubernetes-sigs.github.io/node-feature-discovery/charts
helm dependency build charts/tt-operator   # pulls NFD 0.18.3 + tt-k8s-driver-manager 0.1.0

# Tear down standalone.
helm -n tt-k8s-driver-manager-system uninstall tt-k8s-driver-manager
helm -n node-feature-discovery uninstall nfd

# Install umbrella.
TAG=kluong-initial-extraction
helm -n tt-operator-system upgrade --install tt-operator charts/tt-operator \
  --create-namespace \
  --set tt-k8s-driver-manager.controller.image=ghcr.io/tenstorrent/tt-k8s-driver-manager-controller:$TAG \
  --set tt-k8s-driver-manager.driver.image=ghcr.io/tenstorrent/tt-k8s-driver-manager-installer:$TAG \
  --set tt-k8s-driver-manager.flasher.image=ghcr.io/tenstorrent/tt-k8s-driver-manager-flasher:$TAG

# Patch NFD SAs to pick up ghcr-pull (chart doesn't ship imagePullSecrets;
# driver-manager controller SA inherited the patch from the standalone install).
for sa in $(kubectl -n tt-operator-system get sa -o name | sed 's|serviceaccount/||'); do
  kubectl -n tt-operator-system patch sa "$sa" --type merge \
    -p '{"imagePullSecrets":[{"name":"ghcr-pull"}]}'
done
kubectl -n tt-operator-system rollout restart deploy
```

### Outcome

| | |
|---|---|
| `helm dependency build` | resolves both subcharts cleanly (NFD over HTTP, tt-k8s-driver-manager over OCI) |
| NFD | re-labels all 3 nodes within ~30s of master ready |
| Driver controller | reconciles existing `TenstorrentDriverPolicy aus2-dev2-default`, DS 3/3 Ready, `kmd-version=2.7.0` preserved |
| Firmware controller | reconciles existing `TenstorrentFirmwarePolicy aus2-dev2-test` — **no re-flash** because the original Complete Job from 9h ago is still in `tt-operator-system` and the controller picked it up as evidence the node is at the desired version |

The no-reflash result corroborates the namespace-bookkeeping gotcha from
the standalone run: the firmware controller's decision is per-namespace
Job presence. Same namespace → finds the Complete Job → idles. Different
namespace → no Complete Job → reflashes. Worth a follow-up to read the
node's `current-version` annotation as a tiebreaker.

### Cleanup before merge

- Revert `.github/workflows/helm-release.yaml` on the new repo to its
  original `push: branches: [main]` trigger.
- Squash / clean up the trigger-expansion commit before merging
  tt-k8s-driver-manager to main.

## Containerized-build pivot (2026-05-21)

Switched the driver controller's per-node DaemonSet pod from the
nsenter+host-DKMS installer to the in-container build pattern. Same
end state on disk (a `.ko` matched to the running kernel, loaded), but
the build happens inside the container against host kernel-headers
bind-mounted ro at `/lib/modules` + `/usr/src`, the built `.ko` lives
in a host volume `/var/cache/tt-kmd/<kver>/<version>/`, and the pod
calls `init_module(2)` directly via `CAP_SYS_MODULE` (privileged=true,
no nsenter at all). No host packaging touched.

Builder entrypoint compares `/sys/module/tenstorrent/version` against
`TT_KMD_VERSION` env. Match → idle. Mismatch + refcnt 0 → rmmod, build
(cache miss), insmod. Mismatch + refcnt > 0 → refuse with holder PIDs.

```bash
TAG=sha-1711e9d
helm -n tt-operator-system upgrade tt-operator ~/tt-operator/charts/tt-operator \
  --reuse-values \
  --set tt-k8s-driver-manager.controller.image=ghcr.io/tenstorrent/tt-k8s-driver-manager-controller:$TAG \
  --set tt-k8s-driver-manager.driver.image=ghcr.io/tenstorrent/tt-k8s-driver-manager-builder:$TAG
```

### Gotchas hit along the way

- **`DaemonSet.spec.selector` is immutable.** First pivot commit changed
  `app.kubernetes.io/name` from `tt-kmd-installer` to `tt-kmd-builder`,
  which broke the in-place upgrade — every Update returned `field is
  immutable`. Reverted just the label string; container name + image
  still say "builder".
- **The original `daemonSetNeedsUpdate` diff predicate only checked
  image/pullPolicy/env.** The pivot changed hostPID, hostNetwork,
  volumeMounts, and volumes — none of which were compared, so the
  Update never fired. Replaced with a sha256 hash of (template.spec,
  updateStrategy) stamped as `driver.tenstorrent.com/template-hash`
  on the DS object; predicate is now just an annotation compare.
- **Hash propagation.** First fix set the hash on `desiredDS` but
  `existing.Spec = desiredDS.Spec` didn't copy annotations — so the
  hash never landed on the live object and the predicate always saw a
  mismatch (hot reconcile loop, harmless but visible as `templateGeneration`
  climbing into the hundreds). Second fix: also copy the annotation.

### Outcome

| | |
|---|---|
| DaemonSet template post-pivot | `hostPID=false`, `hostNetwork=false`, container `builder`, volumes `lib-modules,usr-src,tt-kmd-cache` |
| Builder pods | 3/3 Ready in ~20s after rollout |
| `/sys/module/tenstorrent/version` from inside the container | reads `2.7.0` directly — no nsenter, container's own sysfs is the kernel's sysfs |
| Builder entrypoint behavior | "tt-kmd 2.7.0 matches TT_KMD_VERSION on kernel 6.8.0-110-generic; idling" — exercises the fast-path (no build, no rmmod) |
| `kmd-version=2.7.0` node labels | preserved on all 3 nodes |
| `templateGeneration` stability after hash fix | observedGeneration stuck at 449 across 10s sampling — reconcile is idle |

The build path itself (cache miss → clone tt-kmd → `make modules` →
insmod) is **not** exercised by this test because the host already has
2.7.0 loaded. To exercise it, bump the CR's `spec.version` (forces a
mismatch on each node; if refcnt=0, controller will rmmod + rebuild +
reload version-by-version per the DS rolling update). Deferred.

The old nsenter-based installer (`cmd/installer`, `internal/dkms`,
`internal/hostexec`, `images/driver/`) is now vestigial — kept in
tree pending a separate cleanup commit.
