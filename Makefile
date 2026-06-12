# tt-operator is an umbrella chart that installs node-feature-discovery and
# tt-k8s-driver-manager (the latter ships its own controller + images).
#
# Common workflow:
#   make helm-deps      # fetch subchart packages (NFD + tt-k8s-driver-manager)
#   make helm-install   # install the umbrella into a cluster

# Pinned tool versions (helm-docs, helm-unittest), shared with
# .github/workflows/validate.yaml. Single source of truth — bump there.
# Command-line overrides (e.g. `make docs HELM_DOCS_VERSION=v1.x`) still win.
include hack/tool-versions.env

KIND_CLUSTER ?= tt-operator-dev

.PHONY: kind-up
kind-up:
	kind create cluster --name $(KIND_CLUSTER) --config hack/dev/kind-config.yaml

.PHONY: kind-down
kind-down:
	kind delete cluster --name $(KIND_CLUSTER)

.PHONY: helm-deps
helm-deps:
	# helm dependency build pulls one HTTP repo (NFD) and one OCI repo
	# (tenstorrent/helm-charts for tt-k8s-driver-manager). The HTTP repo
	# must be registered first; OCI is used directly.
	helm repo add node-feature-discovery https://kubernetes-sigs.github.io/node-feature-discovery/charts >/dev/null
	helm repo update >/dev/null
	helm dependency build charts/tt-operator

.PHONY: helm-lint
helm-lint:
	helm lint charts/tt-operator

.PHONY: helm-install
helm-install: helm-deps
	helm upgrade --install tt-operator charts/tt-operator \
		--namespace tt-operator-system --create-namespace

.PHONY: docs
docs:
	# Regenerate charts/tt-operator/README.md from Chart.yaml + the `# --`
	# annotations in values.yaml, using README.md.gotmpl as the template.
	# Run through Docker so no local helm-docs install is needed; map to the
	# host user so the generated file isn't left root-owned.
	# HELM_DOCS_VERSION comes from hack/tool-versions.env (see top of file).
	docker run --rm -u $$(id -u):$$(id -g) -v "$(CURDIR):/work" -w /work \
		jnorwood/helm-docs:$(HELM_DOCS_VERSION) helm-docs --chart-search-root=charts

.PHONY: docs-check
docs-check: docs
	# Fails if `make docs` produced changes — i.e. the committed README is stale.
	git diff --exit-code charts/tt-operator/README.md

.PHONY: unittest
unittest: helm-deps
	# Local mirror of the validate.yaml helm-unittest job; CI is the routine
	# runner. Not part of the no-auth local flow: helm-deps pulls the OCI
	# subchart, so this needs a prior `helm registry login ghcr.io`.
	# --verify=false: recent Helm verifies plugin provenance by default, which
	# the helm-unittest git source doesn't provide.
	# HELM_UNITTEST_VERSION comes from hack/tool-versions.env (see top of file).
	helm plugin list | grep -q unittest || \
		helm plugin install https://github.com/helm-unittest/helm-unittest --version $(HELM_UNITTEST_VERSION) --verify=false
	helm unittest --strict charts/tt-operator
