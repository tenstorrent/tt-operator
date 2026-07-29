# Get Support

Two routes exist for tt-operator and its components: a support request for formal
intake, or an issue in the component repository for direct feedback to the
engineers who own the code.

Before either, check that your configuration is within the documented surface in
[Platform Support](platform-support.md), and work through
[Troubleshooting](troubleshooting.md) — several common failures have a fix you can
apply yourself.

## File a support request

Formal intake goes through the Tenstorrent support portal, which routes to the
Customer Success Jira project:

**[Request Support](https://tenstorrent.atlassian.net/servicedesk/customer/portal/1)**

Use this route when you need the issue tracked on Tenstorrent's side, when it
spans more than one component, or when you cannot tell which component is at
fault. The same link is in the **Resources** menu at the top of every
documentation page.

## Report a component issue

If you know which component is misbehaving, file directly in its repository.
tt-operator is the umbrella chart; the others are subcharts it deploys.

| Component | Role | Repository |
|---|---|---|
| TT-Operator | Umbrella chart, install and upgrade, chart values | [tenstorrent/tt-operator](https://github.com/tenstorrent/tt-operator/issues) |
| [Driver Manager](https://docs.tenstorrent.com/tt-k8s-driver-manager/) | Subchart — `tt-kmd` install, firmware flashing, driver policies | [tenstorrent/tt-k8s-driver-manager](https://github.com/tenstorrent/tt-k8s-driver-manager/issues) |
| [Telemetry](https://docs.tenstorrent.com/tt-telemetry/) | Subchart — device metrics, `/metrics` endpoint | [tenstorrent/tt-telemetry](https://github.com/tenstorrent/tt-telemetry/issues) |
| [Fabric Manager](https://docs.tenstorrent.com/tt-fabric-manager/) | Subchart — fabric topology resolution | [tenstorrent/tt-fabric-manager](https://github.com/tenstorrent/tt-fabric-manager/issues) |
| [Device Allocation (DRA)](https://docs.tenstorrent.com/tt-dra-driver/) | Subchart — resource slices, device claims | [tenstorrent/tt-dra-driver](https://github.com/tenstorrent/tt-dra-driver/issues) |

Kernel driver bugs reproducible outside Kubernetes belong in
[tenstorrent/tt-kmd](https://github.com/tenstorrent/tt-kmd/issues) instead.

These repositories require Tenstorrent GitHub access. If you cannot reach them,
file a support request instead.

## What to include

Whichever route you use, include the following. Reports without it usually come
back as a request for it.

- **Chart version** — `helm list -n tt-operator-system`.
- **Kubernetes distribution and version** — `kubectl version`.
- **Device generation** — Wormhole or Blackhole, and how many devices per host.
- **Host OS and kernel** — `uname -a`. Driver build failures almost always trace
  to the kernel or its headers.
- **What you expected, what happened, and the exact error text.**
- **Diagnostics** — the namespace and event capture from
  [Collect diagnostics](continuous-operations.md#collect-diagnostics).
- **Policy resources**, if the problem involves the driver or firmware:

  ```bash
  kubectl get tenstorrentdriverpolicies -o yaml
  kubectl get tenstorrentfirmwarepolicies -o yaml
  ```

- **Logs from the failing pod**, not just its status:

  ```bash
  kubectl -n tt-operator-system logs <pod> --previous
  ```

Redact credentials, registry secrets, and kubeconfig contents before attaching
anything.
