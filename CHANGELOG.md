# cdin-x Changelog

All notable changes to this project will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning follows [Semantic Versioning](https://semver.org/).

---

## [Unreleased]

### Documentation

- **One page per plugin**, in [docs/plugins/](docs/plugins). Each says what the
  plugin does, what you press, and how it works — the third half being the
  reason a rule exists rather than a restatement of it. Sixteen capability
  pages, one for the ten `vim-*` integrations, and one covering the three
  optional plugins.
- **Three "how to make one" guides**, in [docs/building/](docs/building):
  [an integration](docs/building/an-integration.md) with a complete worked
  example, [a theme](docs/building/a-theme.md) listing every colour the editor
  has and what each one is for, and
  [a syntax definition](docs/building/a-syntax-definition.md) for highlighting
  a language.
- **The directory READMEs stay introductions** and gained one line each,
  pointing at the page about that plugin. The line is the only reason a reader
  who lands in `X/core/search/` can find the documentation at all.

Five claims the first drafts made were wrong, and the code is what they are
being corrected against:

- Search has **no prefix syntax** — no `/`, `c/` or `r/`. There is no
  case-sensitive mode; `no_case = true` is set on both search commands and
  nothing reads it back. "Pattern" is a separate *command*, not a prefix.
- The menu filter is a **plain substring**, matched against an entry's label
  and its hint text. The palette is the fuzzy one. A single letter is checked
  as a key *before* it is treated as filter text, so a shortcut does win.
- Menu **context providers do not combine**. The highest-priority provider that
  returns something wins and the rest are not called; `menu.spec.context` is
  the fallback. A provider that never returns `nil` has taken the context away
  from everybody.
- The palette **hides** commands whose predicate does not hold
  (`get_all_valid()` filters), and it is fuzzy — it does not grey them out.
- vim mode has **no page-scrolling movement** and **no `.` to repeat** the last
  change. Its motion set is eight keys, declared as data in
  `vimode/motions.lua`; `r` is redo, not replace. A number typed before a
  command is buffered, and only `gt` / `gT` consume it, so `3gt` is the third
  tab and `3x` is one character.

Two more that only bite someone rebinding a key:

- Arrow strokes are **named, not drawn**: `alt+left`, not `alt+←`. The two
  splits are `ctrl+\` and `ctrl+shift+\`, with a literal backslash.
- `syntax.add` **appends, and the lookup walks backwards**, so the last
  definition registered wins. A second `add` for the same extension silently
  replaces the first. There is no `syntax.remove`, which is why `unload` is
  empty in all six language definitions.

### Documentation

- **Rewritten, and split by what you are trying to do.** `docs/` now holds
  four documents that were previously scattered across the root README and the
  per-directory ones: [getting-started](docs/getting-started.md),
  [installing-plugins](docs/installing-plugins.md),
  [writing-a-plugin](docs/writing-a-plugin.md) and
  [extending-vim](docs/extending-vim.md).
- **Directory READMEs are introductions again.** `X/README.md`,
  `X/integration/README.md` and the sixteen plugin READMEs are now two or three
  paragraphs: what this directory is, and where the detail lives. The long
  analyses they carried — the `fs.list` trap, the `menu.extend` load-order
  trap, the `register()` asymmetry — are either in the new documents or, where
  they were a warning about a specific line of code, in that line's comment,
  which is where somebody hitting it at two in the morning will actually look.
- **`examples/` holds three complete, installable plugins**: a command and a key,
  a document reader with a status-bar pill, and a vim integration. They are
  meant to be copied.
- **Three documentation bugs fixed, not carried forward.**
  `X/core/search/README.md` described a `manifest.lua` inside the plugin, which
  stopped existing when manifests moved inline into `init.lua`. `X/core/tab`,
  `treeview` and `window` claimed to be part of the built-in set and
  un-uninstallable — only `vim` and the `default` theme are `essential`, and
  all three are ordinary optional plugins. The three `X/optional/` READMEs said
  in the same breath that their plugin "is loaded only when installed" and that
  "essential extensions cannot be removed".
- **A dangling reference resolved.** `X/integration/README.md` pointed at
  `X/core/vim/README.md` for "the full table of extension points and a worked
  example". That file was five lines and had no table. It is
  [docs/extending-vim.md](docs/extending-vim.md) now.

### Fixed

- **`config.site_dir` is no longer read as a path.** cdin now exposes
  `config.site_path()`, a resolver, and the name of the directory is a single
  knob — `config.site_dirname`, default `"site"`. cdin-x reads the host's
  resolver instead of computing a path of its own, so renaming the site
  directory in a user's `init.lua` renames it for both halves at once. Before
  this, the literal `"site"` was hardcoded in three independent places and
  changing one did nothing to the other two.
- **`make install` gained `SITE_NAME`.** `make link SITE_NAME=extensions`
  mirrors `config.site_dirname`; a full `SITE=` path still wins. cdin's
  `make test-site-dir` compares the two constants so they cannot drift apart
  silently.


### ⚠️ BREAKING CHANGES

#### cdin-x is installed into a site directory, and its manager is `cdinx`

cdin-x no longer installs *into* a cdin tree. It installs into the editor's
**site directory** — `config.site_path()`, default
`<data_home>/cdin/site` — and nothing in a cdin checkout is touched. That makes the two repositories
independent: cdin can be built and run with no cdin-x present, and cdin-x can
be installed, updated and removed without going near the editor.

- **`core/` is now `cdinx/`.** `require "core.x.<m>"` becomes
  `require "cdinx.<m>"`. The field the bootstrap publishes on the host's
  `core` table is now `core.cdinx`, not `core.x`.
- **`plugins/cdin-x/` is the entry point.** It is installed as a site plugin,
  so the host's own loader finds it, and its `init()` is the single call that
  starts the manager. It does not touch `package.path`: the host has already
  appended the site roots by the time a plugin's `init()` runs.
- **Install with `make install` / `make link`** (or `scripts/install.py`),
  which copy or link exactly three directories — `cdinx/`, `X/`,
  `plugins/cdin-x/` — and write nothing else. `make uninstall` removes them.
  `scripts/install.sh` is replaced by `scripts/install.py` (stdlib, so it runs
  on Windows without a POSIX shell).
- **No `EXEDIR`, no sibling lookup, no assumptions about cdin's tree.**
  `builtin_root()` is `config.site_path()/X`; the registry root is
  `config.registry_dir/X`, overridable with `config.registry_dir` or
  `CDIN_X_REGISTRY`; the site root can be overridden with `CDIN_SITE_DIR`.
- **Host-provided plugins.** A cdin build ships vim, and the host loads it
  before any site plugin runs. The manager collects the host's
  `core.plugins.loaded` at bootstrap and treats those names as *provided*: they
  satisfy a declared dependency but are never loaded a second time. A plugin's
  load guard is per module instance, and the host `dofile`s the entry point
  while a `require`d integration `dofile`s it again, so a second load would
  re-run every registration and collide with itself.
- **Themes are directories again**: `X/themes/<name>/theme.lua`, the layout the
  host's theme registry reads. The catalog recognises the `themes` category
  explicitly, because the generic rules would misread a theme directory
  several different ways.
- **`X/core/cdin_x_bundle.lua` is deleted.** Its only job was to mark the
  built-in bundle as present, and the manifest it marked is generated.
- **`cdinx/preboot.lua` is deleted.** It duplicated the host's pre-boot state
  reader; the session plugin already uses the host's.
- **The essential set is what a cdin build bundles, and nothing else**: the
  `vim` plugin, the `default` theme, and the fonts. An essential plugin must be
  self-contained, because the bundle contains that plugin alone — `make
  validate` checks this.

### Added

- **`scripts/bundle.py`** — produces the mandatory set for a cdin build. Reads
  a checkout, writes real copies, no network. Idempotent: a second run over the
  first run's output is byte-identical. Refuses to write through a symlink or
  junction, and refuses to substitute anything for the fonts.
- **Optional workflow plugins** — `X/core/palette` (command palette,
  `ctrl+shift+p`), `X/core/finder` (find file `ctrl+p`, open file `ctrl+o`,
  open folder `ctrl+shift+o`) and `X/core/modules` (reload module, open the
  user or project module). None is essential, so none is in the bundle.
- **`make` targets** — `install`, `link`, `uninstall`, `bundle`, `validate`,
  `manifest`, `list`. The Makefile was empty.
- **`make validate` grew three checks**: no `EXEDIR` and no `core.x` under
  `cdinx/` or `X/`; self-containment of every essential plugin; and an actual
  run of `scripts/bundle.py`, compared against the exact file set a cdin build
  is entitled to find.
- **`make validate` also checks the `register`/`unregister` seam.** A plugin
  that calls `require("…").register()` on a module that defines no such
  function loads, does nothing, and reports nothing — the manager's `pcall`
  only catches a *raise*, and the resulting `attempt to call a nil value` is
  one line among forty in the log. `init()` and `unregister()` must also be
  symmetric. Both rules are static; each was checked by reintroducing the
  original defect and confirming the failure.

### Changed

- `X/manifest.lua` is regenerated from `cdinx/` and the new theme layout. It is
  written with explicit CRLF, as it always was, but deterministically — in text
  mode the same checkout produced two different files depending on the
  platform.
- `scripts/new-plugin.lua` scaffolds the inline-manifest form every current
  plugin uses, rather than a separate `manifest.lua`.

### Fixed

*(all five pre-existing; found while verifying the cdin/cdin-x split, not
introduced by it — the last three were listed as known issues in
`X/integration/README.md`)*

- **`tab-session` never loaded.** Its `init()` called `register()` on
  `X/integration/tab-session/session.lua`, which returned a table with only
  `save`/`restore` on it — the subscription, the command and the restore
  thread were wired up as *require-time side effects* and there was no
  `register` to call. The manager's `pcall` swallowed the resulting
  `attempt to call a nil value` and the integration simply never appeared.
  `session.lua` now has the `register`/`unregister` seam every other
  integration uses, which also means `unload()` can actually undo the
  subscription instead of leaving a second one behind.
- **`autocomplete` never loaded.** `api.lua` called
  `suggest.refresh_providers(providers)`, which did not exist on `suggest`.
  Added, and implemented by calling `update()` rather than duplicating the
  matching rules.
- **The autocomplete suggestion list only ever held one entry.**
  `suggest.update` filled `suggestions[i]` for `i = 1…max` while its inner
  dedup loop advanced only the *input* cursor `j`, so the same output slot was
  written `max_suggestions` times. Rewritten as a `while` that advances both
  counters, so a run of equal items collapses onto one entry and the next
  item lands in the next slot.
- **`vim-plugin-manager` could load before the menu it extends.** It called
  `menu.extend("vim.main", …)`, which asserts the menu exists, and `vim-menu`
  is what defines it — but the manifest declared only `{ "vim", "menu" }`, so
  nothing ordered them. The catalog is walked with `pairs()`, so the failure
  was intermittent: some runs raised `menu is not defined: vim.main`. It now
  declares `vim-menu`, and the manager's topological sort guarantees the
  order. Verified both ways: with the dependency `vim-menu` sorts first,
  without it `vim-plugin-manager` lands four plugins ahead.
- **`core:open-folder` offered no directories at all.** `suggest_dirs` read
  `entry.type` and `entry.name` off the result of `system.list_dir`, which
  returns an array of *names* — so every entry looked like a file and the
  prompt opened empty, with nothing logged. It now goes through
  `core.fs.list`, which stats each entry and does return the type. This was
  introduced by the move, not inherited: the pre-split runtime had no
  `core:open-folder` definition at all, only the empty view's call to it.
- **`X/core/modules` called `core.reload_module` on a global `core`, and
  `core` is not a global** — the runtime raises on undeclared globals
  (`core.runtime.strict`), so reloading a module that failed to require
  produced `cannot get undefined variable: core` instead of the reason it
  failed. The helper now takes the `core` table `register()` already requires.
- **`:ls` (and `:help`, `:!cmd`, `:net`) left their output behind as "unsaved
  changes", so quitting afterwards asked to discard work that was never
  done.** Each of them built a scratch document, filled it with generated
  text, and then only *renamed* it:

  ```lua
  function doc:get_name() return "ls " .. path end
  ```

  `text_input()` had already moved the undo index, so the document stayed
  dirty forever, had no filename to save to, and the next `:q` counted it —
  and named it. All four now call `doc:clean()` after filling the buffer,
  which is the runtime's own way of saying "this document is not modified". A
  genuine edit is still protected: the fix is not "never ask".
- **vim mode was silently off, and looked like "vim is not loaded".**
  `X/core/vim/init.lua` declared its default (`M.config = { vim_mode_enabled =
  true }`) but never applied it, and nothing in the runtime copies `M.config`
  onto `config`. Every gate in vim mode tests `if not config.vim_mode_enabled
  then return false end`, so with the value left nil the key handler bailed on
  the very first keystroke. The only way to turn it on was
  `vim:toggle-mode` — i.e. `ctrl+alt+v` — which read exactly like "this plugin
  needs activating by hand". The default is now applied in `init()`, guarded
  with `== nil` so a user who set it in their `~/.config/cdin/user/init.lua`
  still wins. `ctrl+alt+v` remains as the manual toggle.
- **`X/core/treeview` overwrote the user's config.** `config.treeview_size` and
  `config.show_hidden_files` were assigned unconditionally at load, so a
  setting the user could see working in their own file was silently replaced
  with the default. Both are guarded with `== nil` now, matching how
  autocomplete and tab-session already did it.

*(Three load failures found at the same time — `tab-session` calling a
`register()` that did not exist, `autocomplete` calling a
`suggest.refresh_providers` that did not exist, and `vim-plugin-manager`
extending the `vim.main` menu without declaring `vim-menu` — are fixed above.
They were recorded here first; that list is superseded.)*

### Added (initial)

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