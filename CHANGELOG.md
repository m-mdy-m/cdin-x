# cdin-x Changelog

All notable changes to this project will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning follows [Semantic Versioning](https://semver.org/).

---

## [Unreleased]

### Added

- Initial cdin-x repository structure
- Core runtime modules: manager, loader, config, manifest, command
- Extension catalog with built-in plugins
- Plugin scaffolding script
- Validation and manifest generation scripts
- Installation script with symlink support
- GitHub Actions CI/CD workflows
- Documentation foundation
- Git hooks for quality assurance
- Extension ecosystem setup with core manager, loader, config, manifest, and command API
- Plugin directory `X/` with categories: `core/`, `languages/`, `optional/`, `themes/`, `lsp/`, `formatters/`, `git/`, `debug/`, `ui/`, `utils/`
- Essential built-in plugins: core, vim, tab, window, treeview, autocomplete, autoreload, autoupdate, projectsearch, session, trimwhitespace
- Plugin scaffolding (`make new-plugin`)
- Registry manifest system with `generate-manifest.lua`
- Extension validation (`scripts/validate.lua`)
- Extension installation (`scripts/install.sh`) with symlink mode for development
- Git hooks for quality assurance (pre-commit, commit-msg, pre-push)
- Documentation structure (architecture, API, development, guides, installation)
- Built-in themes with `theme.lua` only format
- Bundled fonts system

- **Extension ecosystem**: First release of cdin-x as a standalone repository
- **Core runtime**: Manager, loader, config, manifest, and command API
  - `core/init.lua` — entry point and bootstrapping
  - `core/manager.lua` — extension lifecycle management
  - `core/config.lua` — configuration system
  - `core/manifest.lua` — manifest validation
  - `core/command.lua` — command registry
  - `core/session_bootstrap.lua` — session initialization
- **Extension catalog (`X/`)**: 8 categories with official extensions
  - `X/core/` — built-in extensions: core, vim, tab, window, treeview, autocomplete, autoreload, autoupdate, projectsearch, session, trimwhitespace
  - `X/languages/` — language syntax support
  - `X/optional/` — optional extensions
  - `X/themes/` — built-in themes
  - `X/lsp/`, `X/formatters/`, `X/git/`, `X/debug/`, `X/ui/`, `X/utils/` — category scaffolding
- **Plugin scaffolding**: `make new-plugin <name> <category>` creates `init.lua`, `manifest.lua`, and `README.md`
- **Validation system**: `scripts/validate.lua` validates project structure and required files
- **Registry system**: `scripts/generate-manifest.lua` generates catalog metadata
- **Installation**: `scripts/install.sh` installs runtime + built-in extensions into cdin
  - Symlink mode for development (`--symlink`)
  - Copy mode for production
  - Ships only essential extensions by default
- **Themes**: Simplified single-file `theme.lua` format
- **Bundled fonts**: font.ttf, monospace.ttf, icons.ttf, fallback.ttf, emoji.ttf
- **Git hooks**: pre-commit, commit-msg, pre-push for quality assurance
- **Build system**: `Makefile` with targets: `build`, `new-plugin`, `validate`, `registry`, `fmt`, `fmt-test`, `quality`, `check`, `clean`
- **CI/CD**: GitHub Actions workflows for build and release
  - `build.yml` — quality gate, manifest generation, multi-platform build
  - `release.yml` — packaging and GitHub Release creation
- **Documentation**: Full documentation structure
  - `docs/architecture/` — system architecture and plugin system
  - `docs/api/` — extension contract and manager API
  - `docs/development/` — getting started and contributing guide
  - `docs/guides/` — plugin manager usage guide
  - `docs/getting-start.md` — quick start guide
  - `docs/INSTALLATION.md` — installation instructions
  - `docs/Introduction.md` — project overview
- **Examples**: Example extensions in `examples/lua/` and `examples/terraform/`
- **Scripts**: `new-plugin.lua`, `plugin-list.lua`, `validate.lua`, `generate-manifest.lua`, `install.sh`, `README.md`
- **Project config**: `psx.yml` and `.psx-project.yml` for PSX project structure validation
- **Code quality**: `.pre-commit-config.yaml`, `.editorconfig`, `.gitignore`
- **License**: MIT

- Improved extension lifecycle documentation
- Updated `scripts/install.sh` to ship only essential extensions by default

### Structure

- Separated extension ecosystem from `cdin` editor repository
- Established clean boundary: `cdin` owns the runtime, `cdin-x` owns the extensions
- Defined extension contract: `init.lua`, `manifest.lua`, `README.md` per extension
- Themes use single `theme.lua` file — no init, manifest, or README needed
- Runtime never executes extension source directly from the registry clone

### Technical

- Extension lifecycle: `install → enable → load → disable → uninstall`
- Source precedence: built-in (`data/X`) > installed store > registry cache
- Dependency resolution with cycle detection
- Built-in extensions are immutable (cannot be disabled or uninstalled)
- Coroutine-based background work with `core.add_thread`
- Command registration via `command.add(predicate, table)`
- Keymap registration via `keymap.add`