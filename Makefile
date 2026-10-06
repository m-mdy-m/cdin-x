# CDIN-X development tasks.
#
# There is no build here: cdin-x is Lua and data. These targets install it,
# link it for development, and run the checks that guard the catalog.
#
#   make install    copy cdinx/, X/ and plugins/cdin-x/ into the site dir
#   make link       the same three, symlinked, for development
#   make uninstall  remove them again
#   make bundle     produce one bundle for a cdin build (needs BUNDLE and DEST)
#   make validate   structural checks over the catalog
#   make check      one package against the rules (needs PKG)
#   make index      regenerate registry/generated/catalog.lua
#   make manifest   regenerate X/manifest.lua
#   make list       print the catalog
#
# SITE   overrides the site directory.
# DEST   is the data/ directory a cdin build should bundle into.
# BUNDLE is the bundle a build takes its packages from.
# PKG    is a package directory or name, for `make check`.
# LUA    overrides the interpreter (default: lua).

SITE ?=
# Mirrors cdin's config.site_dirname — the site directory's name, the one
# knob that decides what <data_home>/cdin/<name> is called. Set it here as
# well as in your cdin user init.lua if you rename the directory; cdin's
# `make test-site-dir` compares the two so they cannot drift apart silently.
SITE_NAME ?=
LUA  ?= $(shell command -v lua 2>/dev/null || echo lua)
PYTHON ?= python3

# --site is a full path and wins; --site-name is only passed when no full
# path was given, so the two can never disagree.
SITE_ARG = $(if $(SITE),--site "$(SITE)",$(if $(SITE_NAME),--site-name "$(SITE_NAME)",))

.PHONY: install link uninstall bundle validate check index manifest list help

help:
	@echo 'Targets: install, link, uninstall, bundle, validate, check, index, manifest, list'
	@echo ''
	@echo '  install   copy into SITE (default: the host'"'"'s site_dir)'
	@echo '  link      symlink the same three, for development'
	@echo '  bundle    BUNDLE=standard DEST=<dir>  — one bundle for a cdin build'
	@echo '  validate  structural checks over the catalog'
	@echo '  check     one package against the rules: make check PKG=X/core/search'
	@echo '  index     regenerate registry/generated/catalog.lua'
	@echo '  manifest  regenerate X/manifest.lua'
	@echo '  list      print the catalog'

install:
	$(PYTHON) scripts/install.py $(SITE_ARG)

link:
	$(PYTHON) scripts/install.py $(SITE_ARG) --symlink

uninstall:
	$(PYTHON) scripts/install.py $(SITE_ARG) --uninstall

# What a cdin build consumes. `make` in cdin calls this through
# scripts/assemble_data.py; DEST is the build output's data/ directory.
# BUNDLE names the bundle to take the packages from (bundles/<name>.lua);
# a build that names none gets nothing from cdin-x.
bundle:
	@test -n "$(DEST)" || { \
		echo 'DEST is required: make bundle BUNDLE=standard DEST=/path/to/build/data'; exit 1; }
	@test -n "$(BUNDLE)" || { \
		echo 'BUNDLE is required: make bundle BUNDLE=standard DEST=/path/to/build/data'; exit 1; }
	$(PYTHON) scripts/bundle.py --out "$(DEST)" --bundle "$(BUNDLE)"

validate:
	$(LUA) scripts/validate.lua

# One package, against the same rules validate applies to the whole tree.
# PKG is a path or a package name; several may be given, comma-separated.
check:
	@test -n "$(PKG)" || { \
		echo 'PKG is required: make check PKG=X/core/search'; exit 1; }
	@for pkg in $(subst ,, ,$(PKG)); do \
		$(LUA) scripts/check.lua $$pkg || exit 1; \
	done

index:
	$(LUA) scripts/generate-index.lua

manifest:
	$(LUA) scripts/generate-manifest.lua

list:
	$(LUA) scripts/plugin-list.lua
