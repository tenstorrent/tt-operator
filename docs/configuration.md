# Configuration reference

All tt-operator settings are Helm values. The reference below is generated
directly from the chart by [helm-docs](https://github.com/norwoodj/helm-docs)
and regenerated on every docs build, so it always matches the chart you install.

To override a value, pass `--set <key>=<value>` at install or upgrade time, or use
a values file with `-f values.yaml`. See [Installation](installation.md) for
worked examples, including enabling and disabling components and pinning images.

```{include} _generated/chart-values.md
:heading-offset: 1
```
