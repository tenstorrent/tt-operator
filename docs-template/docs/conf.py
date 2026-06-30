# Sphinx configuration for a Tenstorrent "Cloud-Native Support" docs page.
#
# Reusable template. To adopt it in a component repo, copy this `docs/` directory
# and `.github/workflows/docs.yml`, then edit the two project settings below.
# Pages are authored in MyST Markdown. The site builds standalone (your repo's
# GitHub Pages, surfaced at docs.tenstorrent.com/<project_code>) and is also
# consumable by the docs.tenstorrent.com umbrella, which overrides the theme with
# its shared one so the styling tracks the rest of the docsite.
import os
import shutil
from pathlib import Path

# === Per-project settings — edit these when adopting the template ===========
# Display name shown in the docs, and the URL slug (usually the repo name).
project_name = os.environ.get("DOCS_PROJECT", "TT-Component")
project_code = os.environ.get("DOCS_PROJECT_CODE", "tt-component")
# Optional: path (relative to the repo root) to a helm-docs-generated chart
# README to render verbatim into a Configuration page. Leave empty to skip.
chart_readme = os.environ.get("DOCS_CHART_README", "")
# ============================================================================

project = project_name
author = "Tenstorrent"
copyright = "2026, Tenstorrent AI ULC"

_docs_dir = Path(__file__).resolve().parent
_repo_root = _docs_dir.parent

extensions = ["myst_parser", "sphinxcontrib.mermaid", "sphinx_copybutton", "sphinx_togglebutton"]
myst_enable_extensions = ["colon_fence", "deflist"]
myst_heading_anchors = 3
source_suffix = {".md": "markdown", ".rst": "restructuredtext"}
exclude_patterns = ["_build", "_generated", "Thumbs.db", ".DS_Store"]

# -- Optional helm-docs values include ---------------------------------------
# Copies the generated chart README into the docs tree on every build so a
# Configuration page can `{include} _generated/chart-values.md` verbatim.
_generated_dir = _docs_dir / "_generated"


def _sync_chart_values(app, config):
    if not chart_readme:
        return
    src = _repo_root / chart_readme
    _generated_dir.mkdir(exist_ok=True)
    target = _generated_dir / "chart-values.md"
    if src.is_file():
        shutil.copyfile(src, target)
    else:
        target.write_text(
            "```{note}\nChart values reference is unavailable in this build.\n```\n"
        )


# -- Theme -------------------------------------------------------------------
# Use the docs.tenstorrent.com shared theme when building inside the umbrella;
# otherwise the locally-vendored Tenstorrent theme. This is what lets the styling
# follow docs.tenstorrent.com when it changes.
html_theme = "sphinx_rtd_theme"
# Match the docs.tenstorrent.com shared theme's sidebar behavior.
html_theme_options = {
    "collapse_navigation": False,
    "titles_only": True,
    "navigation_depth": 2,
}
_shared_dir = _repo_root.parent.parent / "shared"
if _shared_dir.is_dir():
    html_static_path = [str(_shared_dir / "_static"), str(_docs_dir / "_static")]
    templates_path = [str(_shared_dir / "_templates"), str(_docs_dir / "_templates")]
    html_logo = str(_shared_dir / "images" / "tt_logo.svg")
    html_favicon = str(_shared_dir / "images" / "favicon.png")
else:
    html_static_path = ["_static"]
    templates_path = ["_templates"]
    html_logo = "_static/images/tt_logo.svg"
    html_favicon = "_static/images/favicon.png"

html_title = project_name
html_last_updated_fmt = "%b %d, %Y"

# -- Versioning --------------------------------------------------------------
# Per-release versioned site (docs/build-versions.sh builds each tag + main into
# /<version>/). The versions widget reads these context keys; version URLs
# resolve at /<project_code>/<version>/.
_current_version = os.environ.get("current_version", "latest")
_versions = [v.strip() for v in os.environ.get("TT_DOCS_VERSIONS", "").splitlines() if v.strip()]
html_baseurl = f"https://docs.tenstorrent.com/{project_code}/{_current_version}/"
html_context = {
    "project_code": project_code,
    "cns_component": project_code,
    "versions": _versions or [_current_version],
    "current_version": _current_version,
    "logo_link_url": os.environ.get("homepage", "https://docs.tenstorrent.com/"),
    # Base URL the shared theme's search modal uses to resolve hit URLs.
    "search_site_base_url": "https://docs.tenstorrent.com/",
}


def setup(app):
    app.add_css_file("tt_theme.css")
    app.connect("config-inited", _sync_chart_values)
