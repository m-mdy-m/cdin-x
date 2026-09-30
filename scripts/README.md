# Scripts

Six of them. Two are Python, because they run outside the editor; four are
Lua, because they run inside the toolchain and have no business shelling out to
do it.

## The two that matter to a build

| script | what it does |
| --- | --- |
| `bundle.py` | produce the mandatory set. This is what a cdin build runs. |
| `install.py` | install this repository into the editor's site directory. |

Both are Python 3.8+ standard library. No dependencies, and neither touches the
network — the one thing a build must be able to do twice and get the same
bytes.

```sh
# what a cdin build runs
python3 scripts/bundle.py --out /path/to/cdin/build/<platform>/data

# install into the site directory
python3 scripts/install.py                 # copy
python3 scripts/install.py --symlink       # link, for development
python3 scripts/install.py --uninstall
python3 scripts/install.py --site DIR      # a full path, wins over everything
python3 scripts/install.py --site-name extensions
```

`make bundle DEST=…` and `make install` / `make link` / `make uninstall` are
thin wrappers around these.

### bundle.py

Writes into `--out` exactly five things:

```text
X/core/<n>/**            each essential directory plugin, verbatim
X/core/<n>.lua           each essential single-file plugin, verbatim
plugins/<n>.lua          a shim: return require("X.core.<n>")
themes/<t>/theme.lua     the essential theme
fonts/**                 this repository's fonts/
BUNDLE.lua               return { plugins = {…}, themes = {…} }
```

It deletes and recreates those five entries and nothing else. Whatever else is
in `--out` — notably `core`, the host's own runtime — is left strictly alone,
because a bundler that tidies up its output directory is a bundler that
eventually deletes the thing it was called next to.

It fails rather than working around a problem:

- no essential plugin under `X/core/`
- not exactly one essential theme
- `fonts/` missing or empty
- `--out` is a symlink or a junction

That last one is worth spelling out, because it is a Windows trap. A junction
does not report itself as a symlink through the obvious API, so a check written
for POSIX passes right over one and the script writes *through* it — into
whatever it was pointed at. It refuses any reparse point, not just the kind it
recognises.

Two more properties, both of which exist to be checked rather than trusted:

**Manifests are read as text, not executed.** Lua comments are stripped before
looking for `essential = true`, so a plugin that mentions the marker in a
header comment is not bundled by accident.

**It is idempotent.** A second run over the first run's output is
byte-identical, and no timestamps are preserved. `make validate` runs it twice
and compares, which is the only way to know that claim is still true.

## The four you run by hand

| script | what it does |
| --- | --- |
| `new-plugin.lua` | scaffold a plugin |
| `plugin-list.lua` | print the catalog |
| `validate.lua` | the gate |
| `generate-manifest.lua` | regenerate `X/manifest.lua` |

Run them from the repository root; they use relative paths.

```sh
lua scripts/new-plugin.lua my-plugin core
lua scripts/plugin-list.lua
lua scripts/validate.lua
lua scripts/generate-manifest.lua
```

### validate.lua

The order matters, because it is cheapest-first and stops at the first thing
wrong:

1. the required files exist
2. the fonts exist and are not empty
3. the essential set is exactly one plugin and one theme
4. the theme layout is `<name>/theme.lua`
5. every cross-plugin `require` has a declared dependency behind it
6. every `register` has a matching `unregister`
7. no `EXEDIR` and no `core.x` under `cdinx/` or `X/`
8. every essential plugin is self-contained
9. **`bundle.py` runs, twice, and the two runs are compared** — plus a check
   that the result contains exactly the file set a cdin build is entitled to
   find

Step 9 is the one worth explaining. Everything before it is a rule about this
repository; step 9 is a rule about the *artifact*, checked by producing it.
Self-containment of an essential plugin, for instance, has no cheap static
check — the only true test is that the plugin is copied somewhere alone and
still resolves every `require` inside itself, and that is a real bundler run
rather than a scan.

`CDIN_PYTHON=/path/to/python3 make validate` if `python3` isn't the right
interpreter.

### new-plugin.lua

```sh
lua scripts/new-plugin.lua <name> [core|integration|optional|syntax|themes]
```

Writes an `init.lua` with the manifest inline, the load guard, and a `README.md`
stub. The template is deliberately close to
[examples/01-hello](../examples/01-hello) — start from either.

## `_scan.lua`

Not a script to run. `new-plugin.lua`, `plugin-list.lua` and `validate.lua`
`dofile` it to walk the tree, and it shells out to `find` or PowerShell rather
than assuming a filesystem binding.

That is on purpose: the editor's own Lua has no filesystem module beyond the
handful of things it exposes, so a tool that has to run in both places cannot
use one that only works in one of them.

## Adding a script

1. add it to the table above
2. give it a `make` target if it is something a person would run
3. `make validate` must still pass

The third one is not a formality. `validate.lua` shells out to `bundle.py` and
`generate-manifest.lua` writes a file the catalog is read from, so a new script
is very often something `validate.lua` has to know about.
