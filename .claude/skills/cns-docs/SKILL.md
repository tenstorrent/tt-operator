---
name: cns-docs
description: >-
  Write or edit documentation for tt-operator and the Cloud-Native Support
  components (tt-k8s-driver-manager, tt-telemetry, tt-fabric-manager,
  tt-dra-driver). Use for ANY change under a repo's docs/ tree — new pages,
  edits, cross-links, status/terminology, the shared sidebar theme, and the
  build/preview/publish flow. Encodes the house style and the constraints that
  keep the federated docs.tenstorrent.com site coherent.
---

# Cloud-Native Support documentation

House style and guardrails for the Tenstorrent **Cloud-Native Support (CNS)**
docs. Follow this whenever you touch a `docs/` tree in tt-operator or one of its
component repos. For the one-time scaffold/adoption mechanics, see
`docs-template/README.md` — this skill is about *writing* and *not breaking the
shared site*.

## The docs model (read first)

Each repo builds and publishes **its own** Sphinx + MyST docsite, surfaced under
`docs.tenstorrent.com`. A shared theme + a left-sidebar **component switcher**
tie them together so the whole thing reads as one "Cloud-Native Support" section.

| Repo | Display name | Published at | `project_code` / `cns_component` |
|---|---|---|---|
| tt-operator | TT-Operator | `docs.tenstorrent.com/tt-operator/` | `tt-operator` |
| tt-k8s-driver-manager | Driver Manager | `.../tt-k8s-driver-manager/` | `tt-k8s-driver-manager` |
| tt-telemetry | Telemetry | `.../tt-telemetry/` | `tt-telemetry` |
| tt-fabric-manager | Fabric Manager | `.../tt-fabric-manager/` | `tt-fabric-manager` |
| tt-dra-driver | Device Allocation (DRA) | `.../tt-dra-driver/` | `tt-dra-driver` |
| (hub) | Cloud-Native Support | `.../cloud-native-support/` | `cloud-native-support` |

Docs live in each repo's `docs/` as **MyST Markdown (`.md`)**. `.md` is the
single source of truth — never generate prose from another format at build time
if it can live in `.md` instead.

## Audience & voice

- **Audience:** cluster administrators and platform operators who install and run
  the stack. Assume Kubernetes and Helm literacy; do not explain what a Pod is.
- **Task-oriented:** organize around what the reader is doing (install → configure
  → operate → troubleshoot), not around internal architecture.
- **Voice:** concise, second person, present tense, imperative for steps ("Apply
  the policy", not "You would apply the policy"). Lead with the outcome.
- **Structure:** short sections; tables for at-a-glance facts (status, versions,
  values); a `{mermaid}` diagram for how components fit together. Keep each page
  focused on one job. tt-operator's `docs/index.md` toctrees ("Get Started",
  "Configure and Operate") are the canonical shape.

## Content rules (hard constraints)

These are the mistakes that required a cleanup sweep — do not reintroduce them.

- **`.md` is the source of truth.** For a chart's values reference, render the
  helm-docs-generated `README.md` verbatim (a `README.md.gotmpl` keeps that
  README clean; `conf.py` copies it to `_generated/chart-values.md` and a page
  does `{include} _generated/chart-values.md`). Never hand-duplicate values and
  never post-process the README inside `conf.py`.
- **No internal-only references.** Do not mention helm-docs internals, NVIDIA /
  gpu-operator comparisons, or internal-only projects. Write for an external
  reader with no access to Tenstorrent-internal tooling.
- **No source-repo or blob URLs in prose.** Link to the *published docs page*,
  not to a GitHub file/blob. Exception: linking a public upstream project (e.g.
  kubernetes-sigs/jobset) is fine.
- **Human-readable link text.** Never use `docs/foo.md` or `*.md` as visible link
  text; use the page/feature name.

### Cross-linking (the `/latest/` rule)

- **Within a repo:** use relative Markdown paths (`components/multi-node.md`).
- **To another CNS component:** link the **published site**.
  - A **bare repo root** is fine — `https://docs.tenstorrent.com/tt-telemetry/`
    redirects to `/latest/`.
  - A **deep link to a sub-page MUST include `/latest/`** —
    `https://docs.tenstorrent.com/tt-operator/latest/components/multi-node.html`.
    Without the version segment it **404s** (the root redirect does not cover
    sub-paths). This has bitten us repeatedly; double-check every deep cross-link.

## Status & terminology

- Present components with a **Feature status matrix** (`Component | Capability |
  Status`) plus a short legend defining each status term.
- **Current policy: all components are "Supported."** Do **not** add "beta" tags,
  "Beta feature" admonitions, or "not yet part of the supported surface" hedges
  unless a maintainer explicitly directs it. If a real functional limitation
  exists, state it plainly as a limitation (e.g. "requires resolvable fabric
  topology"), not as a maturity caveat.
- **Names:** the section is **Cloud-Native Support**; the product is
  **TT-Operator**. Use the display names in the table above for components.

## The shared theme & sidebar switcher — don't break it

The CNS switcher is rendered by a vendored `docs/_templates/layout.html`, guarded
by `html_context["cns_component"]` (set in each `conf.py`). Non-CNS projects fall
through to the default menu untouched.

- **All vendored `layout.html` copies must stay byte-identical.** The canonical
  copy is `tenstorrent.github.io` `shared/_templates/layout.html`. If you change
  the switcher, edit the canonical copy, propagate the **exact** bytes to every
  component's `docs/_templates/layout.html` **and** the `docs-template/` seed,
  then verify with `md5`/`diff`. Never hand-tweak one copy.
- The **`cns_items` manifest** inside that file is the single source of truth for
  the switcher's component list and labels; label text must match across copies.
- `conf.py` sets `html_context["project_code"]` and `["cns_component"]`. Leave the
  theme wiring (`html_static_path`/`templates_path` shared-dir fallback) alone
  unless you know the umbrella build.
- Do **not** re-add `content`/`feedback_widget.html` overrides to component
  layouts — those were deliberately removed.

## Build, preview, verify

- **Build gate:** `sphinx-build -b html docs docs/_build/html`. Sphinx **errors**
  fail the build; warnings are surfaced but currently do not fail it (owner
  Markdown is not rewritten for Sphinx). Keep new content warning-clean anyway.
- **Link check:** `sphinx-build -b linkcheck docs docs/_build/linkcheck`
  (non-blocking in CI, but read it).
- **helm-docs coherence:** if you touch chart values docs, keep the generated
  chart `README.md` current or the coherence CI gate fails.
- **Local preview:** `sphinx-autobuild docs docs/_build/html --ignore "*/_generated/*"`
  for one site. To preview the whole CNS section together, build every repo into
  one tree and serve it.
- **CRITICAL — the local preview cannot validate `/latest/` deep links.** A local
  full-site build rewrites `docs.tenstorrent.com/...` URLs to local paths, so a
  broken `/latest/`-less deep link looks fine locally and still 404s in prod.
  **Verify deep cross-links against production** (`curl -o /dev/null -w '%{http_code}'`
  the real URL). Broken deep link → 404; correct `/latest/` link → 200.
- **No local CI tooling.** Validate workflow/lint changes on GitHub Actions, not
  by trying to reproduce the gates locally.

## Publishing & environment gotchas

- Docs **publish from release tags or a manual `workflow_dispatch`, never from a
  push to `main`** (main runs the build gate only). `docs/build-versions.sh`
  builds `main` HEAD as `latest/` **plus every `v*.*.*` tag** into `/<version>/`,
  so a dispatch from `main` still publishes all tagged versions.
- The **`github-pages` environment** gates deploys two ways:
  1. **Required reviewer** — the deploy pauses for approval in the Actions UI
     ("Review deployments"). Approve there.
  2. **Deployment branch/tag policy** — the deploy ref must be allowed. Several
     repos allow only `main`, so a **tag-triggered deploy is rejected** ("Tag
     `vX` is not allowed to deploy") until a `v*.*.*` tag pattern is added to the
     policy (Settings → Environments → github-pages, admin only). Interim: just
     dispatch from `main`.
- A tag **pushed by the default `GITHUB_TOKEN` does not trigger** the deploy
  workflow (recursion guard). Cut release tags with a PAT/GitHub App token, or
  use `workflow_dispatch`.

## PRs & commits

- Commit subject prefix: **`docs:`**. Keep the body about *what changed and why*.
- **No AI-attribution footer** in PR bodies.
- Prefer **folding a docs-only fix into an existing open PR** over opening a new
  one. Branch off **`main`** (not a stale/merged feature branch).

## Adopting docs for a new component

Copy `docs/` and `.github/workflows/docs.yaml` from `docs-template/`, edit the
project settings in `conf.py`, add the component to the shared `cns_items`
manifest in `tenstorrent.github.io` `shared/_templates/layout.html`, and enable
GitHub Pages with the **GitHub Actions** source. Full steps:
`docs-template/README.md`.

## Pre-flight checklist for a docs PR

- [ ] Prose has no internal-only references or source/blob URLs.
- [ ] Every deep cross-link includes `/latest/`; verified 200 against production.
- [ ] Status framing matches policy (no stray "beta").
- [ ] If `layout.html` changed: all vendored copies + the seed are byte-identical.
- [ ] `sphinx-build -b html` is clean (no errors); linkcheck reviewed.
- [ ] Chart-values page still renders from the generated README (if touched).
- [ ] `docs:` commit prefix, no AI attribution, branched off `main`.
