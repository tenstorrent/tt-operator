#!/usr/bin/env bash
# Build the versioned tt-operator docs site for GitHub Pages.
#
# Publishes the current checkout as `latest/` plus every released tag (vX.Y.Z
# that contains docs/) as `<tag>/`, with a root redirect to `latest/` and a
# shared versions list so the docs.tenstorrent.com versions widget can switch
# between them. Version URLs resolve at /tt-operator/<version>/.
#
#   output/
#     index.html   -> redirect to latest/
#     latest/      (current main)
#     v0.1.0/ ...  (each release tag that has docs)
set -euo pipefail

OUT="${1:-output}"
rm -rf "$OUT"
mkdir -p "$OUT"

# Released versions: tags vX.Y.Z that actually contain docs/, newest first.
mapfile -t TAGS < <(git tag -l 'v*.*.*' | sort -Vr)
PUBLISHED=()
for t in "${TAGS[@]:-}"; do
  [ -n "$t" ] || continue
  if git cat-file -e "${t}:docs/conf.py" 2>/dev/null; then
    PUBLISHED+=("$t")
  else
    echo "skip ${t}: no docs/ at that tag"
  fi
done

# Version list shown by the widget (latest first), shared across all builds.
TT_DOCS_VERSIONS="$(printf '%s\n' latest ${PUBLISHED[@]+"${PUBLISHED[@]}"})"
export TT_DOCS_VERSIONS

build_one() {
  local ref="$1" version="$2" src
  echo "::group::build docs: ${version} (${ref})"
  src="$(mktemp -d)"
  # Materialize that ref's tree (docs/ + charts/ for the values include) without
  # touching the working tree, then build it.
  git archive "$ref" | tar -x -C "$src"
  current_version="$version" sphinx-build -q -b html "$src/docs" "$OUT/$version"
  rm -rf "$src"
  echo "::endgroup::"
}

build_one "$(git rev-parse HEAD)" latest
for t in "${PUBLISHED[@]:-}"; do
  [ -n "$t" ] || continue
  build_one "$t" "$t"
done

# Root redirect -> latest.
cat > "$OUT/index.html" <<'HTML'
<!doctype html>
<meta http-equiv="refresh" content="0; url=latest/">
<link rel="canonical" href="latest/">
HTML

echo "Published versions: ${TT_DOCS_VERSIONS//$'\n'/ }"
