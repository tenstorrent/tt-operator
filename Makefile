# tt-operator is an umbrella chart that installs node-feature-discovery and
# tt-k8s-driver-manager (the latter ships its own controller + images).
#
# Common workflow:
#   make helm-deps      # fetch subchart packages (NFD + tt-k8s-driver-manager)
#   make helm-install   # install the umbrella into a cluster

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
