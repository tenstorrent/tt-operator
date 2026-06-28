# Minimal Sphinx Makefile for the component documentation.
# `make html` builds; `make serve` previews locally. Warnings are surfaced but
# do not fail the build. Pass `SPHINXOPTS="-W --keep-going"` for a strict build.
SPHINXOPTS  ?=
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
