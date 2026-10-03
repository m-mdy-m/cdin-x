# manager

The CDIN-X extension manager: a panel, a catalog, and the lifecycle
operations behind them.

`essential = true` — a cdin build bundles this, the same way it bundles vim.
The manager is what makes an installed extension set inspectable and
changeable from inside the editor, and a build whose extensions can only be
managed from outside it is a half-finished editor. Nothing else depends on
it, and it depends on nothing: `dependencies` is empty on purpose.

Everything the manager *offers* stays optional. What is not optional is the
ability to ask what is installed and change it.

## What it is

| | |
| --- | --- |
| `cdinx/init.lua` | the bootstrap: catalog scan, load what is enabled, build the panel |
| `cdinx/panel/` | the panel — six files, listed below |
| `cdinx/command.lua` | six command-palette entries over the same actions |
| `cdinx/config.lua` | every path the manager resolves, and the environment overrides |
| `cdinx/manager/` | catalog, fetching, install layout, enable/disable state, dependency order |

## Layout

`init.lua` here is the entry point a build bundles. The manager's own modules
stay at the checkout root in `cdinx/`, and the `bundle_with` field on this
plugin's manifest is what copies them into a build:

```lua
bundle_with = { "cdinx" },
```

`scripts/bundle.py` copies those paths verbatim into the destination, so
`require "cdinx"` resolves from `<data>/cdinx/` in a build and from the site
directory in an installed set, with no path arithmetic anywhere.

The panel is six files, split so that each can be read on its own:

| file | holds |
| --- | --- |
| `cdinx/panel/init.lua` | builds the view, splits the pane |
| `cdinx/panel/view.lua` | the view: rows, cursor, scrolling, drawing |
| `cdinx/panel/rows.lua` | catalog → rows. Pure |
| `cdinx/panel/search.lua` | what a query matches. Pure |
| `cdinx/panel/commands.lua` | every command, with the predicate that gates it |
| `cdinx/panel/keymap.lua` | the keys, in three maps |

## Keys

| key | does |
| --- | --- |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>M</kbd> | open / close the panel |
| <kbd>Shift</kbd>+<kbd>M</kbd> | the same, in vim normal mode, with `vim-plugin-manager` |
| <kbd>J</kbd> / <kbd>K</kbd>, arrows | move |
| <kbd>/</kbd> or <kbd>Ctrl</kbd>+<kbd>F</kbd> | search; type to filter |
| <kbd>Space</kbd> / <kbd>Enter</kbd> / <kbd>X</kbd> | enable or disable the selected extension |
| <kbd>I</kbd> / <kbd>U</kbd> | install / remove |
| <kbd>D</kbd> | details |
| <kbd>R</kbd> | rescan |
| <kbd>?</kbd> | where the catalog came from |
| <kbd>Ctrl</kbd>+<kbd>R</kbd> | re-download the catalog |
| <kbd>[</kbd> / <kbd>]</kbd> | narrow / widen the panel |
| <kbd>Esc</kbd> | close |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>L</kbd> | the log, which the panel's own messages send you to |

<kbd>Shift</kbd>+<kbd>M</kbd> is **not** bound here. It belongs to
`vim-plugin-manager`, which claims it through vim's own registry, so it only
exists in vim normal mode and only when that integration is installed. The panel
binds <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>M</kbd> globally on purpose: a global
<kbd>Shift</kbd>+<kbd>M</kbd> is also how you type a capital `M`.

## Config

| key | default | what it does |
| --- | --- | --- |
| `config.pluginmanager_size` | `460 * SCALE` | the panel's width |
| `config.pluginmanager_min` | `300 * SCALE` | the narrowest it can be dragged |

Both are set with `or`, not `== nil`, so a value of `0` or `false` in your own
`init.lua` loses to the default. Every other plugin here guards with `== nil`;
this pair does not.

The paths the manager resolves — `site_dir`, `bundle_dir`, `extension_dir`,
`registry_dir`, `state_file`, `registry_url`, `registry_raw_url` — are listed
in [installing-plugins](../../../docs/installing-plugins.md).

## What is not here

**It does not manage the editor.** There is no self-update: replacing the editor
is the user's job, as it is for every other editor. `cdin-x:update` updates
*extensions*, not cdin.

**It does not clone this repository.** The catalog is one file —
`X/manifest.lua`, about 16 KiB — downloaded over plain HTTPS from
`raw.githubusercontent.com`, and installing an extension downloads exactly the
files that extension's manifest entry lists. `curl` (or `wget`, or PowerShell on
Windows) is the downloader; git is not involved at any point.

`cdinx/manager/registry.lua` still accepts an injected syncer and prefers one if
something registers it, but nothing in this repository does, so the HTTPS path
is what runs.

**It does not resolve dependency conflicts.** `deps.lua` orders what is
installed, and `install` pulls in a declared dependency that is missing. What
it will not do is tell you that two installed extensions want incompatible
versions of a third — there is no version negotiation here.