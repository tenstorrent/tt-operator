<!--
Root document (root_doc = "_nav" in conf.py). This renders the shared
Cloud-Native Support sidebar that appears on every component's site, so the
independently-built sites feel like one section.

Adopting: keep this list identical across components (it is the shared
manifest). Point THIS component's entry at its local docs (e.g. `<index>`); leave
the others as absolute docs.tenstorrent.com URLs so they link to each component's
own published site. The current component's pages nest automatically under its
entry; the others are links.
-->

# Cloud-Native Support

Run Tenstorrent accelerators on Kubernetes. `tt-operator` is the umbrella Helm
chart that installs and coordinates the components below. Select a component in
the sidebar.

```{toctree}
:maxdepth: 2
:caption: Cloud-Native Support

TT-Operator <https://docs.tenstorrent.com/tt-operator/>
Node Feature Discovery <https://docs.tenstorrent.com/tt-operator/components/node-feature-discovery.html>
Driver Manager <https://docs.tenstorrent.com/tt-k8s-driver-manager/>
Firmware <https://docs.tenstorrent.com/tt-k8s-driver-manager/firmware.html>
Telemetry <https://docs.tenstorrent.com/tt-telemetry/>
Fabric Manager (beta) <https://docs.tenstorrent.com/tt-fabric-manager/>
Device Allocation (beta) <https://docs.tenstorrent.com/tt-dra-driver/>
Multi-Node Scheduling (beta) <https://docs.tenstorrent.com/tt-operator/components/multi-node.html>
```
