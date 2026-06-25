# Configuration reference

All tt-operator settings are Helm values. The reference below is generated
directly from the chart by [helm-docs](https://github.com/norwoodj/helm-docs)
and mirrors `charts/tt-operator/README.md` exactly — it is regenerated on every
docs build, so it always matches the chart you install.

To override a value, pass `--set <key>=<value>` at install/upgrade time, or use a
values file with `-f values.yaml`. See [Installation](installation.md) for
worked examples (enabling/disabling components, pinning images, and more).

```{include} _generated/chart-values.md
:heading-offset: 1
```
