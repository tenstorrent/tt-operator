# Tenstorrent component docs template

A drop-in Sphinx + MyST documentation scaffold for a component in the
docs.tenstorrent.com **Cloud-Native Support** section. It gives a component repo
a branded docs site, a build gate on every change, and a versioned GitHub Pages
deploy, so the component's owners only have to write Markdown.

The published site is surfaced at `docs.tenstorrent.com/<project_code>` and is
also consumable by the docs.tenstorrent.com umbrella, which overrides the theme
with its shared one so the styling tracks the rest of the docsite.

## What's included

```
docs/
  conf.py              # Sphinx config — edit the project settings at the top
  requirements.txt     # Sphinx + MyST + theme + mermaid + copybutton
  Makefile             # `make html`, `make linkcheck`, `make serve`
  build-versions.sh    # builds each release tag + main into /<version>/
  index.md             # starter page — replace with your docs
  _static/             # vendored Tenstorrent theme (fallback when standalone)
  _templates/          # versions widget
.github/workflows/docs.yml   # build gate (PRs) + versioned Pages deploy
```

## Adopt it

1. Copy `docs/` and `.github/workflows/docs.yml` into your repo.
2. Edit the project settings at the top of `docs/conf.py`:
   - `project_name` — the display name (for example, `Driver Manager`).
   - `project_code` — the URL slug, usually the repo name.
   - `chart_readme` — optional path to a helm-docs-generated chart `README.md`
     to render verbatim into a Configuration page. Leave empty to skip.
3. Replace `docs/index.md` with your documentation and add more pages plus a
   `{toctree}` as it grows.
4. Enable GitHub Pages with the **GitHub Actions** source (Settings -> Pages).

## Preview locally

```bash
python3 -m venv .venv
.venv/bin/pip install -r docs/requirements.txt
.venv/bin/sphinx-autobuild docs docs/_build/html --ignore "*/_generated/*"
```

Open http://127.0.0.1:8000. Saving a file rebuilds and refreshes the browser.

## How publishing and versioning work

- On a pull request, the docs are built with warnings treated as errors, plus a
  link check. Nothing is deployed.
- On a push to `main` or a `v*.*.*` tag, `build-versions.sh` builds `main` as
  `latest/` and each release tag as `<version>/`, then deploys the whole tree to
  GitHub Pages. The versions widget switches between them.

## Render a chart's values 1:1

If your component ships a helm chart, set `chart_readme` in `conf.py` to the path
of its helm-docs-generated `README.md`. It is copied into the docs on every build
and can be rendered verbatim with:

````markdown
```{include} _generated/chart-values.md
:heading-offset: 1
```
````

so the values reference always matches the chart, with no manual duplication.
