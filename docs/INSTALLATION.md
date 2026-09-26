# Installation

## Installing cdin (most people want this)

From inside a `cdin` checkout:

```bash
make cdin-x-setup
make run
```

`cdin-x-setup` does **not** clone this repository. It downloads one small
index file (`X/manifest.lua`) and then fetches, file by file, only:

- the plugin engine runtime (`core/`) — always required
- the plugins under `X/core/*` marked `essential = true` in their
  `manifest.lua` — the minimum needed to run cdin at all
- the `default` theme

No `git` is required for this path — only `curl` and `lua`. However many
plugins or themes exist in cdin-x, installing cdin only ever downloads this
same small, fixed set of files.

Everything else — optional plugins (`X/optional/*`), language packs
(`X/languages/*`), and every non-default theme — stays in this repository
and is installed **on demand, one at a time**, from inside the running
editor's extension manager. It is never downloaded up front. This mirrors
how lite-xl's `lpm install <plugin>` or nvim's `lazy.nvim` fetch a single
plugin rather than an entire plugin ecosystem.

## Development checkout (cdin-x contributors)

If you're working on cdin-x itself — adding a plugin, editing the manager,
editing a built-in extension — clone it as a sibling of `cdin` so your edits
are picked up immediately:

```text
workspace/
├── cdin/
└── cdin-x/
```

```bash
cd cdin
make cdin-x-dev-setup
```

This clones `cdin-x` (if not already present next to `cdin`) and symlinks
`data/core/x`, `data/X`, and `data/fonts` straight into your checkout, so
changes show up on the next run without re-installing. Ordinary installs
should use `make cdin-x-setup` instead — this path is for people editing
cdin-x's own source.

## Runtime installation

Installed optional extensions are stored in the user's data directory. A
registry clone (as used by the dev checkout above) is only a catalog/source
cache; it is not loaded directly by cdin.

## First start

cdin creates the external user configuration file automatically. Existing
installations can delete their old `data/user` directory after migrating
any personal settings.
