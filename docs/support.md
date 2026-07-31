# Get Support

Support for tt-operator and its components goes through the Tenstorrent Customer
Success portal. Tenstorrent triages the request and routes it to the team that
owns the affected component, so one route covers the whole stack.

Before filing, check that your configuration is within the documented surface in
[Platform Support](platform-support.md), and work through
[Troubleshooting](troubleshooting.md) — several common failures have a fix you can
apply yourself.

## File a support request

**[Request Support](https://tenstorrent.atlassian.net/servicedesk/customer/portal/1)**

Use this route for anything the documentation does not resolve: a component that
will not start, a regression after an upgrade, unexpected device behavior, or a
question about whether a configuration is supported. You do not need to know
which component is at fault — describe what you observed and Tenstorrent routes
it from there. The same link is in the **Resources** menu at the top of every
documentation page.

## Name the component, if you know it

Naming the component in the request shortens triage. tt-operator is the umbrella
chart; the others are subcharts it deploys.

| Component | Owns |
|---|---|
| TT-Operator | Umbrella chart, install and upgrade, chart values |
| [Driver Manager](https://docs.tenstorrent.com/tt-k8s-driver-manager/) | `tt-kmd` install, firmware flashing, driver policies |
| [Telemetry](https://docs.tenstorrent.com/tt-telemetry/) | Device metrics, `/metrics` endpoint |
| [Fabric Manager](https://docs.tenstorrent.com/tt-fabric-manager/) | Fabric topology resolution |
| [Device Allocation (DRA)](https://docs.tenstorrent.com/tt-dra-driver/) | Resource slices, device claims |

If a fault reproduces outside Kubernetes — on bare metal, with the driver loaded
by hand — say so. That points triage at the kernel driver rather than the
Kubernetes stack.

## What to include

Include the following in the request. Reports without it usually come back as a
request for it.

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
