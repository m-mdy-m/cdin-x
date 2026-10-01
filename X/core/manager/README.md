# manager

The CDIN-X extension manager: a panel, a catalog, and the lifecycle
operations behind them.

`essential = true` — a cdin build bundles this, the same way it bundles vim.
The manager is what makes an installed extension set inspectable and
changeable from inside the editor, and a build whose extensions can only be
managed from outside it is a half-finished editor. Nothing else depends on
it, and it depends on nothing: `dependencies` is empty on purpose.

## What it is

| | |
| --- | --- |
| `cdinx/init.lua` | the bootstrap: catalog scan, load what is enabled, build the panel |
| `cdinx/panel.lua` | the panel — list, search, toggle, install, uninstall |
| `cdinx/command.lua` | the same actions as command-palette entries |
| `cdinx/manager/` | catalog, install layout, enable/disable state, dependency order |

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

## Keys

| key | does |
| --- | --- |
| <kbd>Shift</kbd>+<kbd>M</kbd>, <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>M</kbd> | open / close the panel |
| <kbd>J</kbd> / <kbd>K</kbd>, arrows | move |
| <kbd>/</kbd> or <kbd>Ctrl</kbd>+<kbd>F</kbd> | search; type to filter, <kbd>Esc</kbd> to leave search |
| <kbd>Space</kbd> / <kbd>Enter</kbd> | enable or disable the selected extension |
| <kbd>I</kbd> / <kbd>U</kbd> | install / uninstall |
| <kbd>D</kbd> | details |
| <kbd>R</kbd> | rescan |

## What is not here

No network. Fetching a catalog is the git extension's job, and the manager
reports an absent registry rather than going and getting one. No dependency
resolution beyond ordering what is installed. No self-update: replacing the
editor is the user's job, as it is for every other editor.
