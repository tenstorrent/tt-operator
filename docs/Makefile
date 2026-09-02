# SPDX-License-Identifier: Apache-2.0
# SPDX-FileCopyrightText: 2026 Tenstorrent USA, Inc.

# Minimal Sphinx Makefile for the tt-operator documentation.
# `make html` mirrors CI (warnings are errors). `make serve` previews locally.
SPHINXOPTS  ?= -W --keep-going
SPHINXBUILD ?= sphinx-build
SOURCEDIR   = .
BUILDDIR    = _build

.PHONY: help html linkcheck serve clean
help:
	@$(SPHINXBUILD) -M help "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS)

html:
	@$(SPHINXBUILD) -b html "$(SOURCEDIR)" "$(BUILDDIR)/html" $(SPHINXOPTS)

linkcheck:
	@$(SPHINXBUILD) -b linkcheck "$(SOURCEDIR)" "$(BUILDDIR)/linkcheck"

serve: html
	@python -m http.server -d "$(BUILDDIR)/html" 8000

clean:
	@rm -rf "$(BUILDDIR)" _generated
