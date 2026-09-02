# Contributing to tt-operator

Thank you for your interest in contributing. This document explains how to
report problems, propose changes, and get a pull request merged.

## Code of Conduct

This project follows the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md).
By participating you agree to uphold it. Report unacceptable behavior to
ospo@tenstorrent.com.

## Reporting bugs and requesting features

- Report bugs and request features through
  [GitHub Issues](https://github.com/tenstorrent/tt-operator/issues).
- Before opening an issue, search existing issues to avoid duplicates.
- For bugs, include the tt-operator chart version, Kubernetes distribution
  and version, the Helm values you installed with, and the output of
  `kubectl get pods -n tt-operator-system`. If the problem is inside a single
  component (driver manager, DRA driver, telemetry, fabric manager), file it
  in that component's repository instead; this repository only packages them.
- Do **not** report security vulnerabilities through public issues. Follow the
  process in [SECURITY.md](SECURITY.md) instead.

## Submitting changes

Bug fixes and new functionality are submitted as pull requests against the
`main` branch.

1. Fork the repository and create a branch from `main`.
2. Make your change. Chart changes need a matching unit test under
   `charts/tt-operator/tests/` where behavior changes.
3. Run the checks listed below and make sure they pass.
4. Open a pull request. Describe what the change does and why, and link any
   related issues.

Pull requests are reviewed on a weekly cadence. A maintainer may ask for
changes before merging. Pull requests are merged with a squash merge, so keep
the pull request title and description accurate; they become the commit
message on `main`.

### Developer workflow

```bash
make helm-deps      # fetch subchart dependencies
make helm-lint      # helm lint the umbrella chart
make unittest       # helm unittest suite under charts/tt-operator/tests/
make lint           # yamllint, actionlint, and the other pre-commit hooks
make docs           # build the Sphinx documentation site locally
make docs-check     # build docs with warnings as errors, as CI does
make kind-up        # create a local kind cluster for manual testing
make helm-install   # install the chart into the current kube context
```

Subchart versions are pinned in `charts/tt-operator/Chart.yaml` and managed by
Renovate. When bumping a subchart whose CRDs changed, mention it in the pull
request so the release notes can call out the manual CRD re-apply step
described in the README.

### Coding standards

- YAML must pass `yamllint` with the repository's `.yamllint.yaml`.
- GitHub Actions workflows must pass `actionlint`.
- Regenerate `charts/tt-operator/README.md` with `helm-docs` after changing
  `values.yaml` or the chart's `README.md.gotmpl`; CI fails on drift.
- Add or update documentation under `docs/` for any user-visible change to
  values, prerequisites, or install steps.

### License headers

Every source file must carry an SPDX header. For new files written for this
project, use:

```yaml
# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 Tenstorrent USA, Inc.
```

Use the comment syntax appropriate to the file type. Do not modify the
headers of third-party files.

### Commit messages

Use a short imperative summary line (72 characters or fewer), optionally
followed by a blank line and a longer explanation of the motivation for the
change.

## License

By contributing, you agree that your contributions are licensed under the
[Apache License 2.0](LICENSE).
