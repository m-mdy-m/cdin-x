# cdin-x

**cdin-x** is the extension ecosystem for [cdin](https://github.com/m-mdy-m/cdin).
It is deliberately separate from the editor runtime: cdin is a runtime that
knows nothing about extensions, and everything an extension can be — the
mandatory set a build bundles, and the optional workflows and plugins a user
installs — lives here.

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

---

## What it is

Two kinds of thing live here, and the difference matters.

**The mandatory set**: the `vim` plugin, the `default` theme, and the fonts.
A cdin build without these is not a working editor, so a build copies them in
with [`scripts/bundle.py`](scripts/bundle.py). They are selected by a marker
— `essential = true` in a plugin's manifest — and nothing else is.

**The optional set**: everything else. The command palette, the file finders,
the project tree, tabs, search, git, and the themes beyond the default. A user
installs these into their own site directory, and the editor's in-app manager
handles them from there.

## Install

```sh
git clone https://github.com/m-mdy-m/cdin-x.git
cd cdin-x

make link     # symlink into the site directory (development)
make install  # copy into the site directory
make uninstall
```

## Bundling for a cdin build

This is what a cdin build runs, at build time, from a checkout of this
repository:

```sh
make bundle DEST=/path/to/cdin/build/<platform>/data
```

which is `scripts/bundle.py --out <DEST>`. It writes the essential plugins,
the essential theme, the fonts, a one-line shim per plugin, and a `BUNDLE.lua`
index. Real copies, no network, idempotent — a second run over the first
run's output is byte-identical.

It fails, loudly, rather than working around a problem: no essential plugin,
not exactly one essential theme, a missing or empty `fonts/`, or a `--out` that
is a symlink or junction.

## For cdin builds

```sh
make CDINX_DIR=/path/to/cdin-x   # from the cdin checkout
```

`CDINX_DIR` is the only thing cdin knows about this repository, and it is a
path. `make bin` in cdin compiles the binary and needs nothing from here.

## Developing an extension

```sh
make validate    # structural checks over the whole catalog
make manifest    # regenerate X/manifest.lua
make list        # print the catalog
lua scripts/new-plugin.lua <name> [core|integration|optional|syntax]
```

`make validate` is the gate. It checks the required files, the essential set,
the theme layout, the dependency rules, the `register`/`unregister` seam every
plugin is expected to expose, self-containment of every essential plugin, and
that no file under `cdinx/` or `X/` refers to a cdin install layout or to the
old `core.x` module namespace.

An **essential** plugin — one a cdin build bundles — must be self-contained:
every `require "X.…"` inside it has to resolve within its own subtree, because
the bundle contains that plugin and nothing else. `make validate` enforces it.


## Documentation

- [X/README.md](X/README.md) — the extension layout and conventions
- [X/integration/README.md](X/integration/README.md) — how plugins are wired
- [X/core/vim/README.md](X/core/vim/README.md) — vim's extension points
- cdin's [extension contract](https://github.com/m-mdy-m/cdin/blob/main/docs/architecture/extension-contract.md)
  — what cdin guarantees, and what may be relied on

## Requirements

A cdin that implements the extension contract: a site directory, a plugin
loader, `core.command_view`, and the command and keymap registries. cdin-x
assumes nothing about where that cdin is installed, and fetches nothing at
runtime.

## License

MIT — see [LICENSE](LICENSE).
