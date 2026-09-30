# cdin-x Changelog

All notable changes to this project will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).
Versioning follows [Semantic Versioning](https://semver.org/).

---

## [Unreleased]

---

## [0.1.0] — 2026-09-30

First tagged release. 13 commits, 134 files changed, +7,354 / −735.

cdin-x at this release is the **extension ecosystem** and nothing else: a plugin
catalog, an installer, a bundler that a cdin build calls, the mandatory set a
cdin build cannot start without, and the optional workflow plugins. It installs
into the editor's **site directory** and touches nothing in a cdin checkout, so
the two repositories are independent — cdin can be built and run with no
cdin-x present, and cdin-x can be installed, updated or removed without going
near the editor.

The contract cdin provides and cdin-x may rely on is written down in cdin's
[`docs/architecture/extension-contract.md`](https://github.com/m-mdy-m/cdin/blob/main/docs/architecture/extension-contract.md).
Paired release: **cdin `0.2.0-alpha.2`**, which is what bundles this.

### What a 0.1.0 install contains

| Path | What it is |
|------|------------|
| `plugins/cdin-x/` | the entry point — one site plugin whose `init()` starts the manager |
| `cdinx/` | the manager: catalog, deps, registry, lifecycle, runtime, state |
| `X/core/` | 15 capability plugins |
| `X/integration/` | 4 integrations — `vim` (the ten `vim-*` capabilities), `session`, `tab-session`, `git-treeview` |
| `X/optional/` | 3 plugins the user installs deliberately: `rtl_toggle`, `theme_switcher`, `unicode_inspect` |
| `X/syntax/` | 6 language definitions: `c`, `javascript`, `lua`, `markdown`, `python`, `typescript` |
| `X/themes/` | 10 themes, one directory each: `<name>/theme.lua` |
| `fonts/` | 5 fonts + 2 licences — 7 files, and a cdin build without them cannot start |
| `scripts/` | `bundle.py`, `install.py`, and `validate.lua`, `generate-manifest.lua`, `new-plugin.lua`, `plugin-list.lua`, `_scan.lua` |
| `docs/`, `examples/` | documentation, and three complete plugins to copy |

### ⚠️ BREAKING CHANGES

#### cdin-x is installed into a site directory, and its manager is `cdinx`

cdin-x no longer installs *into* a cdin tree. It installs into the editor's
**site directory** — `config.site_path()`, default
`<data_home>/cdin/site` — and nothing in a cdin checkout is touched. That makes the
two repositories independent: cdin can be built and run with no cdin-x present, and
cdin-x can be installed, updated and removed without going near the editor.

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
- **All ten `X/themes/*.lua` files became directories** (`<name>/theme.lua`),
  which is the layout `core.themes` reads and the layout
  `themes.add_root()` can be pointed at.

### Added

#### `scripts/bundle.py` — what a cdin build consumes

Reads a checkout and writes **real copies**. No network, no fetch, no
substitute. Idempotent: a second run over the first run's output is
byte-identical. It refuses to write *through* a symlink or junction, and it
refuses to substitute anything for the fonts — a build with no fonts cannot
start, and silently shipping a substitute would be worse than not shipping.

Verified output of `python3 scripts/bundle.py --out <dir>` on this release:

```
X/core/vim/**            verbatim copy of the vim plugin, whole subtree
plugins/vim.lua          one line: return require("X.core.vim")
themes/default/theme.lua the essential theme
fonts/**                 5 fonts + 2 licences
BUNDLE.lua               { plugins = { "vim" }, themes = { "default" } }
```

The `plugins/<name>.lua` shim is what the host's loader finds, since it walks
`data/plugins` for entry points and the plugin itself lives under `X/`. The
`X.*` namespace is preserved so `require "X.core.vim"` resolves the same way in
a bundle and in a site install.

#### Optional workflow plugins

Three of cdin's commands were runtime commands and are now ordinary, non-essential
plugins under `X/core/`. None is in the bundle, and a vim-only build stays usable
through vim's Ex commands — `:e`, `:w`, `:q`, `:new`, `:cd` — with none of them
installed.

| Plugin | Provides | Keys |
|--------|----------|------|
| `palette` | `core:find-command` | `ctrl+shift+p` |
| `finder` | `core:find-file`, `core:open-file`, `core:open-folder` | `ctrl+p`, `ctrl+o`, `ctrl+shift+o` |
| `modules` | `core:reload-module`, `core:open-user-module`, `core:open-project-module` | none; use the palette |

The host invokes these by name in one place — the empty view — through
`command.perform`, which returns false and does nothing for a name nothing
registered. That is deliberate: a missing optional command is a silent no-op, not
an error.

#### The registry syncer is a hook, and the git plugin provides it

`cdinx/manager/registry.lua` will pull or clone the catalog, and it refuses to
know that git exists. It asks for a syncer instead, and the git plugin injects
one: `M.sync_registry` in `X/core/git/manager/ops.lua`, registered through
`manager.set_registry_syncer` in the plugin's `register()`.

Fetching a repository is a git operation, so it lives with the git code rather
than in a manager that would otherwise have to `require` a capability the editor
itself is unaware of. `sync_registry(root, url)` derives the checkout with a
separator-safe parent join — a bare `..` after a trailing separator is a no-op on
some platforms — probes for an existing checkout with `rev-parse --git-dir`, and
then either `pull --ff-only` or `clone --depth 1`. It returns `true`, or `false`
plus a reason.

**With the git plugin absent, "Refresh Catalog" reports that the syncer is
unavailable** rather than quietly doing nothing and leaving the reader to wonder
whether the catalog is stale.

#### The Makefile

There was no build here — cdin-x is Lua and data — and no Makefile at all. There
is one now, and its targets install, link and check rather than compile:

| Target | What it does |
|--------|--------------|
| `make install` | copy `cdinx/`, `X/` and `plugins/cdin-x/` into the site directory |
| `make link` | the same three, symlinked, for development |
| `make uninstall` | remove them again |
| `make bundle DEST=…` | the mandatory set, for a cdin build to consume |
| `make validate` | structural checks over the catalog |
| `make manifest` | regenerate `X/manifest.lua` |
| `make list` | print the catalog |

`SITE=` overrides the site directory by full path, `SITE_NAME=` overrides only its
*name*, and `PYTHON=` / `LUA=` pick the interpreters. Only one of the two is passed
to `install.py`, so a full path and a name can never disagree.

#### `make validate` grew the checks that matter

Beyond the required files, the theme layout and the dependency rules, validation
now covers the things that are cheap to get wrong and expensive to debug at
runtime — and two of them fail silently rather than loudly, which is the whole
reason to check statically:

- **No `EXEDIR`, and no `core.x` namespace**, anywhere under `cdinx/` or `X/`.
  `EXEDIR` is a global the host defines as the directory the binary lives in;
  depending on it assumes a cdin install layout, which is exactly what cdin-x
  must not assume. A leftover `require "core.x.…"` resolves to nothing on a host
  that has no such module and fails at load time rather than build time. Only
  code is checked, and `--` comments and string literals are stripped first, so a
  line that merely *mentions* either word is not a failure.
- **Every essential plugin is self-contained.** The bundler copies one essential
  plugin and its own files with no other plugin alongside it, so an essential
  plugin that requires another `X` plugin bundles into something that cannot
  load. This is not a style rule — it is the property that makes the bundle
  valid, and it cannot be checked any other way, because the failure only appears
  in a built cdin.
- **The `register` / `unregister` seam.** A plugin that calls
  `require("…").register()` on a module that defines no such function loads, does
  nothing, and reports nothing: the manager's `pcall` around `init()` only
  catches a *raise*, and the resulting `attempt to call a nil value` is one line
  among forty in a log nobody opens. Both shapes are checked — the call must name
  a function, on the entry point or on a sibling it requires — and the pair must
  be symmetric. It is static, not a load: it cannot see a nil field two levels
  deep in someone's own module.
- **The bundle itself.** The one check that exercises the real code path.
  `scripts/bundle.py` is run and its output compared against the exact file set a
  cdin build is entitled to find — run twice, so the artifact is *checked* rather
  than assumed. Everything else above is a statement about the source; this one
  is a statement about the thing that ships.

Resolving the `register` seam reads the table an `init.lua`'s `register()` call
resolves to **without running it**: `dofile` would execute the body, and a
top-level `require` in a manifest-carrying file is a catalog hazard that
validation must not itself trigger.

#### `examples/` — three complete, installable plugins

`01-hello` (a command and a key), `02-word-count` (a document reader with a
status-bar pill) and `03-vim-word-count` (a vim integration). Each is a plugin
that actually installs, meant to be copied rather than read.

### Changed

- **`X/manifest.lua` is regenerated from `cdinx/` and the new theme layout.** It is
  written with explicit CRLF, as it always was, but *deterministically* — in text
  mode the same checkout produced two different files depending on the platform.
- **`scripts/new-plugin.lua` scaffolds the inline-manifest form** every current
  plugin uses, rather than a separate `manifest.lua`.
- **Documentation is split by what you are trying to do.** `docs/` now holds
  four documents that were previously scattered across the root README and the
  per-directory ones: [getting-started](docs/getting-started.md),
  [installing-plugins](docs/installing-plugins.md),
  [writing-a-plugin](docs/writing-a-plugin.md) and
  [extending-vim](docs/extending-vim.md).
- **Directory READMEs are introductions again.** `X/README.md`,
  `X/integration/README.md` and the plugin READMEs are now two or three
  paragraphs: what this directory is, and where the detail lives. The long
  analyses they carried — the `fs.list` trap, the `menu.extend` load-order trap,
  the `register()` asymmetry — are either in the new documents or, where they were
  a warning about a specific line of code, in that line's comment, which is where
  somebody hitting it at two in the morning will actually look.
- **`README.md` rewritten** to lead with the three commands that matter —
  `make install`, `make validate`, `make bundle` — instead of the repository's
  history.

### Fixed

Two from the split itself:

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

Eight found while verifying the split — not introduced by it, and the last three
were listed as known issues in `X/integration/README.md`:

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

### Documentation

- **One page per plugin**, in [docs/plugins/](docs/plugins) — 18 files. Each says
  what the plugin does, what you press, and how it works; the third half being the
  reason a rule exists rather than a restatement of it. Sixteen capability pages,
  one covering the three optional plugins, and one for the ten `vim-*`
  integrations.
- **Three "how to make one" guides**, in [docs/building/](docs/building):
  [an integration](docs/building/an-integration.md) with a complete worked
  example, [a theme](docs/building/a-theme.md) listing every colour the editor
  has and what each one is for, and
  [a syntax definition](docs/building/a-syntax-definition.md) for highlighting
  a language.
- **`CONTRIBUTING.md` rewritten** (176 lines) around what a plugin author
  actually needs to know before their first pull request.
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

**Three documentation bugs fixed, not carried forward.**
`X/core/search/README.md` described a `manifest.lua` inside the plugin, which
stopped existing when manifests moved inline into `init.lua`. `X/core/tab`,
`treeview` and `window` claimed to be part of the built-in set and
un-uninstallable — only `vim` and the `default` theme are `essential`, and
all three are ordinary optional plugins. The three `X/optional/` READMEs said
in the same breath that their plugin "is loaded only when installed" and that
"essential extensions cannot be removed".

**A dangling reference resolved.** `X/integration/README.md` pointed at
`X/core/vim/README.md` for "the full table of extension points and a worked
example". That file was five lines and had no table. It is
[docs/extending-vim.md](docs/extending-vim.md) now.

### Known issues and limitations

- **Bundled vim and site-installed integrations can come from different cdin-x
  versions**, and there is no version negotiation — cdin's `make bundle` reads
  whatever `CDINX_DIR` points at, and the installed site set is whatever the user
  installed. The compatibility surface between them is `X.core.vim.registry`: an
  integration that uses its documented extension points works across the gap, one
  that reaches into a vim module's internals does not. This is the one known
  limitation, and it is written down on both sides.
- **"Refresh Catalog" needs the git plugin.** The manager asks for a syncer and
  this release only ships one in `X/core/git`. With it absent, refresh reports
  that the syncer is unavailable rather than pretending to succeed. A syncer for
  any other transport is a drop-in: implement `sync_registry(root, url)` and pass
  it to `manager.set_registry_syncer`.
- **There is no CI.** `.github/workflows/` is empty, so `make validate` runs
  nowhere automatically. Nothing in this repository is checked on push.
- **`make fmt`, `make fmt-test` and `make check` do not exist**, though
  `.github/PULL_REQUEST_TEMPLATE.md` still offers them as checklist items. The
  Makefile's real quality gate is `make validate`.
- **`scripts/load_check.lua` is referenced by a comment in `scripts/validate.lua`
  and does not exist.** The static seam check says so itself — it cannot see a
  nil field two levels deep in someone's own module — and the load check it points
  at was never written.
- **`syntax.add` has no `remove`,** so `unload` is empty in all six language
  definitions. Redefining an extension replaces the previous definition (the
  lookup walks backwards); removing one is not possible.

### Stability

- Every rule the split depends on has a static check behind it, and each was
  verified by reintroducing the original defect and confirming the failure.
- The bundler's output was verified against the file set cdin's
  `docs/architecture/extension-contract.md` documents, and is byte-identical on a
  second run.
- cdin `0.2.0-alpha.2`'s `make test-workflows` boots the real loader against a
  cdin-x checkout and asserts that `palette`, `finder` and `modules` register
  their commands, that `ctrl+p` / `ctrl+shift+p` / `ctrl+o` / `ctrl+shift+o` each
  have **exactly one** command bound to them, and that unloading the three through
  the manager detaches both the commands and the strokes. Run it before tagging a
  paired release.

### Provenance

The `Added (initial)`, `Structure` and `Technical` lists that used to sit at the
end of `[Unreleased]` described the repository **before** this split, and several
of their claims no longer hold: `core/` is `cdinx/`, `scripts/install.sh` is
`scripts/install.py`, manifests moved inline into `init.lua`, and the
`X/lsp/`, `X/formatters/`, `X/git/`, `X/debug/`, `X/ui/` and `X/utils/` category
directories are not in the tree. They have been replaced by the layout table at
the top of this entry rather than carried forward.
