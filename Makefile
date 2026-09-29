# CDIN-X development tasks.
#
# There is no build here: cdin-x is Lua and data. These targets install it,
# link it for development, and run the checks that guard the catalog.
#
#   make install    copy cdinx/, X/ and plugins/cdin-x/ into the site dir
#   make link       the same three, symlinked, for development
#   make uninstall  remove them again
#   make bundle     produce the mandatory set for a cdin build (needs DEST)
#   make validate   structural checks over the catalog
#   make manifest   regenerate X/manifest.lua
#   make list       print the catalog
#
# SITE   overrides the site directory.
# DEST   is the data/ directory a cdin build should bundle into.
# LUA    overrides the interpreter (default: lua).

SITE ?=
LUA  ?= $(shell command -v lua 2>/dev/null || echo lua)
PYTHON ?= python3

SITE_ARG = $(if $(SITE),--site "$(SITE)",)

.PHONY: install link uninstall bundle validate manifest list help

help:
	@echo 'Targets: install, link, uninstall, bundle, validate, manifest, list'
	@echo ''
	@echo '  install   copy into SITE (default: the host'"'"'s site_dir)'
	@echo '  link      symlink the same three, for development'
	@echo '  bundle    DEST=<dir>  — mandatory set for a cdin build'
	@echo '  validate  structural checks over the catalog'
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
bundle:
	@test -n "$(DEST)" || { \
		echo 'DEST is required: make bundle DEST=/path/to/build/data'; exit 1; }
	$(PYTHON) scripts/bundle.py --out "$(DEST)"

validate:
	$(LUA) scripts/validate.lua

manifest:
	$(LUA) scripts/generate-manifest.lua

list:
	$(LUA) scripts/plugin-list.lua
