#!/usr/bin/env bash
# Refresh vendored CRDs in charts/tt-operator/crds/ from the upstream
# release matching the version pinned in charts/tt-operator/Chart.yaml.
#
# Run this after bumping a subchart's version in Chart.yaml that owns
# its CRDs out-of-band (the upstream Helm chart ships zero CRDs of its
# own and expects the cluster admin to kubectl-apply them separately).
#
# Currently handles: jobset.
#
# Usage:
#   hack/refresh-vendored-crds.sh
#
# Requires: gh (with read access to kubernetes-sigs/jobset releases) and yq.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHART_YAML="${REPO_ROOT}/charts/tt-operator/Chart.yaml"
CRDS_DIR="${REPO_ROOT}/charts/tt-operator/crds"

mkdir -p "${CRDS_DIR}"

# --- jobset ---
# Read the jobset version pinned in Chart.yaml. Upstream tags releases
# as v<version>, so prepend `v`.
JOBSET_VERSION="$(yq -r '.dependencies[] | select(.name == "jobset") | .version' "${CHART_YAML}")"
if [[ -z "${JOBSET_VERSION}" || "${JOBSET_VERSION}" == "null" ]]; then
  echo "error: could not read jobset version from ${CHART_YAML}" >&2
  exit 1
fi

TAG="v${JOBSET_VERSION}"
SOURCE="https://github.com/kubernetes-sigs/jobset/releases/download/${TAG}/manifests.yaml"
TMP="$(mktemp)"
trap 'rm -f "${TMP}"' EXIT

echo "Pulling jobset ${TAG} manifests..."
gh release download "${TAG}" \
  --repo kubernetes-sigs/jobset \
  --pattern manifests.yaml \
  --output "${TMP}" \
  --clobber

DEST="${CRDS_DIR}/jobset-crds.yaml"

{
  cat <<HEADER
# JobSet CRD vendored from kubernetes-sigs/jobset ${TAG}
# (matches the jobset subchart version in charts/tt-operator/Chart.yaml).
#
# The upstream jobset Helm chart deploys the controller + RBAC + webhook
# but ships zero CRDs — they live in a separate manifests.yaml released
# with each tag. We vendor the CRD here so umbrella installs are
# CRD-complete out of the box.
#
# Helm convention: \`crds/\` is applied on \`helm install\` only, never on
# \`helm upgrade\` or \`helm uninstall\`. When bumping the jobset subchart
# version in Chart.yaml, refresh this file via:
#   hack/refresh-vendored-crds.sh
# and run \`kubectl apply -f charts/tt-operator/crds/\` against any
# already-installed cluster before / after the \`helm upgrade\`.
HEADER
  yq eval 'select(.kind == "CustomResourceDefinition")' "${TMP}"
} > "${DEST}"

echo "Wrote ${DEST}"
