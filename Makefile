ifeq ($(OS),Windows_NT)
  VERSION   ?= $(shell git describe --tags --always --dirty 2>NUL || echo dev)
  MKDIR_P   = if not exist "$(1)" mkdir "$(1)"
  RM_RF     = if exist "$(1)" rmdir /s /q "$(1)"
  FMT_CHECK = powershell -NoProfile -Command "$$out = luafmt -c core/ X/ scripts/ 2>NUL; if ($$out) { Write-Host 'not lua-formatted:'; Write-Host $$out; exit 1 }"
  SET_EXEC  = rem exec bit not needed on Windows - git runs hooks via sh
  ECHO_HELP = @echo
else
  VERSION   ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo dev)
  MKDIR_P   = mkdir -p $(1)
  RM_RF     = rm -rf $(1)
  FMT_CHECK = out=$$(luafmt -c core/ X/ scripts/ 2>/dev/null); \
              if [ -n "$$out" ]; then echo "not lua-formatted:"; echo "$$out"; exit 1; fi
  SET_EXEC  = chmod +x .husky/pre-commit .husky/commit-msg .husky/pre-push
  ECHO_HELP = @echo
endif

.PHONY: help setup hooks build clean new-plugin \
        plugin-list registry fmt fmt-test validate \
        quality check

help:
	$(ECHO_HELP) cdin-x Build System
	$(ECHO_HELP) ============================
	$(ECHO_HELP)
	$(ECHO_HELP)   setup       enable git hooks in .husky
	$(ECHO_HELP)   build       build and validate
	$(ECHO_HELP)   new-plugin  create a new plugin scaffold
	$(ECHO_HELP)   plugin-list list all extensions in X/
	$(ECHO_HELP)   registry    regenerate catalog manifest
	$(ECHO_HELP)   fmt         format Lua code
	$(ECHO_HELP)   fmt-test    check formatting
	$(ECHO_HELP)   validate    validate project structure
	$(ECHO_HELP)   quality     fmt-test + validate
	$(ECHO_HELP)   check       quality (CI equivalent)
	$(ECHO_HELP)   clean       remove build artifacts

setup hooks:
	git config core.hooksPath .husky
	@$(SET_EXEC)
	@echo hooks enabled - .husky

build:
	@$(call MKDIR_P,$(BUILD_DIR))
	@lua scripts/validate.lua
	@lua scripts/generate-manifest.lua
	@echo built cdin-x $(VERSION)

new-plugin:
	@lua scripts/new-plugin.lua $(filter-out $@,$(MAKECMDGOALS))

plugin-list:
	@lua scripts/plugin-list.lua

registry:
	@lua scripts/generate-manifest.lua
	@echo registry manifest updated

fmt:
	@luafmt -w core/ X/ scripts/ 2>/dev/null || true
	@echo code formatted

fmt-check:
	@$(FMT_CHECK)
	@echo formatting OK

validate:
	@lua scripts/validate.lua
	@echo validation passed

quality: fmt-check validate
	@echo quality OK

check ci: quality
	@echo check passed

clean:
	@$(call RM_RF,$(BUILD_DIR))
	@echo clean complete

%:
	@:
