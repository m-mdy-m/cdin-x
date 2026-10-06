# cdin-x

The extension ecosystem for [cdin](https://github.com/m-mdy-m/cdin).

cdin is the editor — window, renderer, text pipeline, document, command and
key registries — and it knows nothing about plugins. This repository is
everything the editor isn't.

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

## Why it's a separate repository

So that both halves can be wrong independently.

A cdin checkout builds and runs with nothing from here present: `make bin`
needs no cdin-x, and the editor starts, renders, edits, and answers
<kbd>Ctrl</kbd>+<kbd>N</kbd> with an empty site directory. Conversely, this
repository installs, updates and removes itself without going near an editor
installation. Neither one reads a path into the other except at build time, and
there that path is one variable, `CDINX_DIR`.

The cost is a line in a build script. What it buys is that "the editor is
broken" and "an extension misbehaves" stop being the same investigation.

## Two kinds of thing live here

**The mandatory set**: the `vim` plugin, the extension `manager`, the `default`
theme, and the fonts. A cdin build without these is not a working editor, so a
build copies them in from this repository. They are selected by a marker —
`essential = true` in a plugin's manifest — and exactly three things carry it:
`vim`, `manager`, and the `default` theme. Nothing else does.

`make validate` fails if **no** essential plugin is found, and fails if the
number of essential *themes* is not exactly one. It reports the plugin count but
does not bound it, so a third essential plugin would pass silently.

The manager is in that list because an editor whose only answer to "what is
installed, and how do I change that" is a script in another directory is a
half-finished editor, and the person who finds out is always the one who just
installed something. Everything it *offers* stays optional; what is not optional
is the ability to ask.

**Everything else**: the command palette, the file finders, the project tree,
tabs, search, git, the themes beyond the default. A user installs these from
inside the editor, and the manager handles them from there.

## Install

```sh
git clone https://github.com/m-mdy-m/cdin-x.git
cd cdin-x

make link      # symlink into the site directory — for development
make install   # copy into the site directory
make uninstall
```

That writes four directories into cdin's **site directory** and nothing else:

```text
<site>/cdinx/            the manager
<site>/X/                what has not moved into packages/ yet (vim)
<site>/packages/         the first-party packages
<site>/plugins/cdin-x/   the entry point cdin's loader finds
```

The site directory is `<data_home>/cdin/site` — `data_home` being
`$XDG_DATA_HOME` or `~/.local/share` on POSIX, and `%LOCALAPPDATA%`, then
`%APPDATA%`, then `%USERPROFILE%\AppData\Local` on Windows. It is the editor's
to name, so if you renamed it:

```sh
make link SITE_NAME=extensions        # just the name
make link SITE=/somewhere/else         # or a full path, which wins
```

`site` is the word vim and neovim use for exactly this directory
(`:h site-dir`) — third-party content, as opposed to the editor's own.

## Then, from inside cdin

<kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>M</kbd> opens the manager (<kbd>Shift</kbd>+<kbd>M</kbd> in vim normal mode, with `vim-plugin-manager`). Pick something, press
<kbd>Space</kbd>, and it's installed and loaded. No restart, and after this
one-time install you don't come back to a terminal for it.

**[Start here](docs/getting-started.md)** if you just want to use it.

## For a cdin build

A cdin build consumes this repository through one variable:

```sh
make CDINX_DIR=/path/to/cdin-x      # in the cdin checkout
```

which runs `scripts/bundle.py`, writing exactly six things into the build's
`data/` directory: each essential plugin, the essential theme, the fonts, a
one-line shim per plugin, a `BUNDLE.lua` index, and whatever support paths the
plugins declared with `bundle_with`. Real copies, no network.

It fails rather than working around a problem — no essential plugin, not
exactly one essential theme, a missing or empty `fonts/`, a `bundle_with` path
that is not there, or an output directory that is a symlink or junction, which
it will not write through.

It is also idempotent: a second run over the first run's output is
byte-identical, and no timestamps are preserved. A bundle that differs between
builds of the same commit is a bug, and this is what makes that checkable
rather than a matter of trust.

Run it by hand with:

```sh
make bundle DEST=/path/to/cdin/build/<platform>/data
```

## Developing

```sh
make validate        # the gate
make manifest        # regenerate X/manifest.lua
make list            # print the catalog
# (no test target exists yet)

```

`make validate` is the one that matters. It checks the required files, the
essential set, the theme layout, declared dependencies, the
`register`/`unregister` symmetry, that nothing under `cdinx/` or `X/` refers
to a cdin install layout or to the old `core.x` namespace, and that every
essential plugin is self-contained. Then it **runs the real bundler twice and
compares**, so the thing a cdin build actually consumes gets checked instead
of assumed.

Every rule it enforces is a failure that is invisible until much later — a
`module not found` at startup in a built editor, or a plugin that works until
somebody uninstalls the other one. The reasons are in
[CONTRIBUTING.md](CONTRIBUTING.md).

## The layout

Every one of these has a README that says what the directory is and stops
there.

| directory | holds | the rule that shapes it |
| --- | --- | --- |
| [`X/core/`](X/core) | one capability each | may not depend on another X plugin |
| [`X/integration/`](X/integration) | the wiring between capabilities | declares what it needs; may depend on two or more |
| [`X/optional/`](X/optional) | plugins nobody is waiting for | may not depend on another X plugin |
| [`X/syntax/`](X/syntax) | language definitions, one file each | the host only |
| [`X/themes/`](X/themes) | themes, as `<name>/theme.lua` | the host only |
| [`cdinx/`](cdinx) | the manager | reads `config.site_path()` and nothing else about paths |
| [`plugins/`](plugins) | the entry point cdin's loader finds | one file |
| [`scripts/`](scripts) | bundler, installer, and the tools validate runs | stdlib and plain `lua`, no dependencies |
| [`examples/`](examples) | three complete plugins to copy | not part of the catalog |

## Documentation

| you want | read |
| --- | --- |
| to use it | [docs/getting-started.md](docs/getting-started.md) |
| to install plugins | [docs/installing-plugins.md](docs/installing-plugins.md) |
| to use one plugin | [docs/plugins/](docs/plugins/) — one page each, with what you press and how it works |
| to write a plugin | [docs/writing-a-plugin.md](docs/writing-a-plugin.md) — and [examples/](examples/) |
| to make an integration | [docs/building/an-integration.md](docs/building/an-integration.md) |
| to make a theme | [docs/building/a-theme.md](docs/building/a-theme.md) |
| to highlight a language | [docs/building/a-syntax-definition.md](docs/building/a-syntax-definition.md) |
| to extend vim mode | [docs/extending-vim.md](docs/extending-vim.md) |
| to work on this repo | [CONTRIBUTING.md](CONTRIBUTING.md), [scripts/README.md](scripts/README.md) |
| to know what cdin guarantees | [the extension contract](https://github.com/m-mdy-m/cdin/blob/main/docs/architecture/extension-contract.md) |

Start at [docs/README.md](docs/README.md) if you would rather pick one.

## Requirements

A cdin that implements the extension contract: a site directory, a plugin
loader, `core.command_view`, and the command and key registries. Nothing here
assumes where that cdin is installed, and nothing is fetched at runtime except
the plugin catalog.

Python 3.8+ standard library for the two scripts, and `lua` for the four tools.
No dependencies beyond that.

## License

MIT — see [LICENSE](LICENSE).
