# Scripts

Seven of them. Two are Python, because they run outside the editor; five are
Lua, because they run inside the toolchain and have no business shelling out to
do it.

## The two that matter to a build

| script | what it does |
| --- | --- |
| `bundle.py` | produce one named bundle. This is what a cdin build runs. |
| `install.py` | install this repository into the editor's site directory. |

Both are Python 3.8+ standard library. No dependencies, and neither touches the
network — the one thing a build must be able to do twice and get the same
bytes.

```sh
# what a cdin build runs
python3 scripts/bundle.py --out /path/to/cdin/build/<platform>/data --bundle standard

# install into the site directory
python3 scripts/install.py                 # copy
python3 scripts/install.py --symlink       # link, for development
python3 scripts/install.py --uninstall
python3 scripts/install.py --site DIR      # a full path, wins over everything
python3 scripts/install.py --site-name extensions
```

`make bundle BUNDLE=… DEST=…` and `make install` / `make link` /
`make uninstall` are thin wrappers around these.

### bundle.py

Asks for a bundle by name — `standard`, `minimal` or `empty` — and writes its
closure into `--out`:

```text
X/<path>/**             each package the closure reached, verbatim
packages/<path>/**      ditto, for the ones that have moved
themes/<t>/theme.lua    each theme the closure reached
fonts/**                this repository's fonts/
plugins/<n>.lua         a shim: return require("<n>")
BUNDLE.lua              return { plugins = {...}, themes = {...} }
```

The closure is the named packages plus their `depends` and nothing else. `--bundle`
defaults to `standard`, and a build that wants nothing at all names `empty` —
which is also the only bundle that ships no fonts.

It deletes and recreates those entries and nothing else. Whatever else is in
`--out` — notably `core`, the host's own runtime — is left strictly alone,
because a bundler that tidies up its output directory is a bundler that
eventually deletes the thing it was called next to.

It fails rather than working around a problem:

- a bundle naming a package that does not exist
- a package reaching outside the closure
- `fonts/` missing or empty, for any bundle but `empty`
- `--out` is a symlink or a junction

That last one is worth spelling out, because it is a Windows trap. A junction
does not report itself as a symlink through the obvious API, so a check written
for POSIX passes right over one and the script writes *through* it — into
whatever it was pointed at. It refuses any reparse point, not just the kind it
recognises.

Two more properties, both of which exist to be checked rather than trusted:

**Manifests are read as text, not executed.** Every `package.lua` goes through
`cdinx/schema.lua`'s sandbox — no `require`, no `io`, no `os`, no threads, no
metatables, and a bounded budget — so a manifest cannot do anything but return a
table.

**It is idempotent.** A second run over the first run's output is
byte-identical, and no timestamps are preserved. `make validate` runs it for
every bundle and compares, which is the only way to know that claim is still
true.

## The five you run by hand

| script | what it does |
| --- | --- |
| `new-plugin.lua` | scaffold a package, a theme, or a language definition |
| `check.lua` | the per-package rules, run against one directory |
| `plugin-list.lua` | print the catalog |
| `validate.lua` | the gate |
| `generate-manifest.lua` | regenerate `X/manifest.lua` |

Run them from the repository root; they use relative paths.

```sh
lua scripts/new-plugin.lua my-package system
lua scripts/check.lua packages/system/my-package
lua scripts/plugin-list.lua
lua scripts/validate.lua
lua scripts/generate-manifest.lua
```

### validate.lua

The order matters, because it is cheapest-first and stops at the first thing
wrong:

1. the required files exist
2. every `package.lua` parses in the sandbox and passes the schema
3. `name` matches the directory, and a `theme` package is named `theme-*`
4. nothing declares `essential` — there is no such field
5. the fonts exist and are not empty, for every bundle but `empty`
6. each bundle's closure is closed, and reaches nothing it did not name
7. every `features` key has a file at exactly `features/<key>.lua`, and every
   feature and `with` file defines both `enable` and `disable`
8. every `with` file reaches only the package its own manifest key named
9. every cross-package `require` is either a declared `depends` or inside a
   `with` entry
10. every `register` has a matching `unregister`
11. no `EXEDIR` and no `core.x` under `cdinx/`, `X/` or `packages/`
12. no keystroke the input layer cannot produce
13. **`bundle.py` runs, once per bundle, and the outputs are compared against the
    file set a cdin build is entitled to find**

Step 13 is the one worth explaining. Everything before it is a rule about this
repository; step 13 is a rule about the *artifact*, checked by producing it. A
closure that reaches further than its bundle named is only visible in the output,
and a stale link or a wrong path in a `plugins/<n>.lua` shim is a *file* the
build consumes rather than a line the validator can read.

`CDIN_PYTHON=/path/to/python3 make validate` if `python3` isn't the right
interpreter.

### new-plugin.lua

```sh
lua scripts/new-plugin.lua <name> [editing|navigation|system|vcs]
lua scripts/new-plugin.lua <name> themes
lua scripts/new-plugin.lua <name> syntax
```

Writes a `package.lua` and an `init.lua` for a package, a `theme.lua` for a
theme, one file for a language definition — and a `README.md` except for the
language definition, which lives beside five others under a README of its own.

**It refuses to write anything if the files already exist.** That is not
defensiveness: `new-plugin.lua lua syntax` would otherwise truncate the real
`X/syntax/lua.lua`, because the write mode is `"wb"` and nothing asks first.

**The templates are not `string.format`.** Placeholders are `@NAME@` and
`@CATEGORY@`, substituted with `gsub`. A template full of Lua patterns inside a
`string.format` is a countdown — `%.%` becomes `invalid conversion`, a stray `%s`
in a comment becomes `bad argument #5 to 'format'` — and this script had both,
which is why it crashed for every category except themes and nobody noticed:
the one category it worked for was not the one the usage text led with.

The theme template's colour keys are copied from `nord/theme.lua` rather than
invented, because a wrong key name is **invisible** — the runtime falls back to
the default for a key nobody supplied. `["function"]` is bracketed there because
`function` is a reserved word and `function = "#x"` is not a table constructor.

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