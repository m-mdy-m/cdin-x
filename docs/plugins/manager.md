# manager

The panel: what is installed, what is available, and what you can change.

`essential = true` — one of three things a cdin build bundles, with `vim` and
the `default` theme. That is the whole argument for it: everything the manager
*offers* stays optional, and what is not optional is being able to ask what is
installed and change it. A build with nothing else installed still has a panel
a keystroke away.

## Keys

| key | does |
| --- | --- |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>M</kbd> | open / close |
| <kbd>M</kbd> | the same, in vim normal mode, with `vim-plugin-manager` installed |
| <kbd>J</kbd> / <kbd>K</kbd>, <kbd>↓</kbd> / <kbd>↑</kbd> | move |
| <kbd>/</kbd> or <kbd>Ctrl</kbd>+<kbd>F</kbd> | search |
| <kbd>Space</kbd> / <kbd>Return</kbd> / <kbd>X</kbd> | enable or disable |
| <kbd>I</kbd> | install |
| <kbd>U</kbd> | remove |
| <kbd>D</kbd> | details |
| <kbd>R</kbd> | rescan what is on disk |
| <kbd>?</kbd> | where the catalog came from |
| <kbd>Ctrl</kbd>+<kbd>R</kbd> | re-download the catalog index (one file, no git) |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>L</kbd> | open the log |
| <kbd>[</kbd> / <kbd>]</kbd> | narrower / wider |
| <kbd>Esc</kbd> | close |

**<kbd>M</kbd> is not the manager's.** It is claimed by
`vim-plugin-manager` through vim's own registry, so it works in vim normal mode
only, and only when that separately-removable integration is installed. The
panel binds <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>M</kbd> globally instead,
because a global <kbd>Shift</kbd>+<kbd>M</kbd> is also how you type a capital
`M` — bound globally it opened the panel from insert mode and from the <kbd>:</kbd>
prompt.

**Two modes.** While browsing, letters are commands and the footer says so.
Press <kbd>/</kbd> and every printable key goes into the query instead, including
the ones bound above — because typing `j` has to produce a `j`, or a filter over
a list of extensions cannot contain most of the alphabet. <kbd>Backspace</kbd>
deletes, <kbd>Return</kbd> keeps the filter and puts the cursor on the best
match, <kbd>Esc</kbd> leaves the search **but keeps the filter**. Only
`pluginmanager:search-clear`, which has no key, drops the query.

## The list

Three sections, in the order that answers "what is here, and what is mine":

| section | what is in it | what you can do |
| --- | --- | --- |
| **In the editor** | what the build or the installed set brought | nothing: present, visible, not removable |
| **Installed** | what you put here, by category | enable, disable, update, remove |
| **Available** | what the catalog offers and this does not have | install |

The marker column is one character, one column: `#` part of the editor, `x`
installed, `o` disabled, `+` not installed. Names are clipped rather than
allowed to run under the version and status on the right.

The title bar carries the counts — `12 in editor  4 installed  29 available` —
which is a fourth piece of status information the sections do not show.

**Details are not the same list every time.** <kbd>D</kbd> offers *Install* for
something available, *Enable / Disable / Update / Uninstall* for something
installed, *Locked* only for something locked or essential, and *Open README* and
*Back* always.

## Search

Substring over the name, the description and the category first — that is what
"find me the one about trees" means, and it is exact. Fuzzy over the name
second, so `tv` still finds `treeview`. Never the other way round: a fuzzy
match that quietly returns things you did not ask for is worse than a miss.

With a query, the best match is ranked to the top within its category rather
than sorted alphabetically, and the filter band above the list says how many of
how many matched.

## Commands with no key

Deliberate, and listed here because the rule is that an unkeyed command says so:
`pluginmanager:open`, `pluginmanager:close`, `pluginmanager:open-readme`,
`pluginmanager:catalog-status`, `pluginmanager:search-clear`,
`pluginmanager:activate-cursor`, and the three `pluginmanager:search-*` commands
that the searching-mode keys drive.

Six more live on the palette side, in `cdinx/command.lua`:
`cdin-x:menu`, `pluginmanager:menu`, `cdin-x:catalog`, `cdin-x:update`,
`cdin-x:clean`, `cdin-x:refresh`.

## What it can install

| you have | the panel offers |
| --- | --- |
| a cdin build | the set the build ships, and nothing installable |
| cdin-x installed into the site directory | the whole catalog, installable |
| a catalog index on disk (`config.registry_dir`) | that index |

**The network, and how little of it.** Opening the panel the first time downloads
one file, the index — `X/manifest.lua`, about 16 KiB. Search reads only that.
Installing downloads only the files of the extension you picked; a theme is one
`theme.lua`. Nothing is cloned, and git is not involved at any point.
`registry.lua` will still use an injected syncer if something registers one, and
nothing in this repository does.

## Config

| key | default | what it does |
| --- | --- | --- |
| `config.pluginmanager_size` | `460 * SCALE` | the panel's width |
| `config.pluginmanager_min` | `300 * SCALE` | the narrowest it can be dragged |

Both are set with `or` rather than `== nil`, so `0` or `false` in your own
`init.lua` loses to the default — which is the opposite of every other plugin
here. The paths the manager resolves are listed in
[installing-plugins](../installing-plugins.md).

## What persists

Enable and disable, in this repository's own state file
(`<data_home>/cdin/extensions.lua`), keyed by extension name, alongside the
version and install time of anything installed from a local path. The runtime
keeps no registry of its own, and nothing here writes to a cdin checkout.

## Layout

| file | holds |
| --- | --- |
| `cdinx/init.lua` | the bootstrap |
| `cdinx/command.lua` | the six palette commands |
| `cdinx/config.lua` | every path, and the environment overrides |
| `cdinx/panel/init.lua` | builds the view, splits the pane |
| `cdinx/panel/view.lua` | the view: rows, cursor, scrolling, drawing |
| `cdinx/panel/rows.lua` | catalog → rows. Pure |
| `cdinx/panel/search.lua` | what a query matches. Pure |
| `cdinx/panel/commands.lua` | every command, with the predicate that gates it |
| `cdinx/panel/keymap.lua` | the keys, in three maps |
| `cdinx/manager/` | catalog, fetching, lifecycle, dependency order, the store searcher |

`rows.lua` and `search.lua` are pure functions over plain data, and `view.lua`
is drawn against a recording renderer. There is no test runner for them in this
repository, so that separation is currently a design claim rather than a checked
one.

## How it works

`cdinx/init.lua` bootstraps three things in order: scan the catalog, load what is
enabled, then build the panel. The panel is required last, because everything it
lists is something the first two put there.

The panel is a **locked split** — its own pane on the right of the active one,
holding its width whether open or shut. A view added and removed on each open
would take the pane's tabs with it and resize the document every time.

**Gating happens on the commands, not on the keys.** Every `keymap.add` here is
a bare `keymap.add(MAP)` with no predicate, because `keymap.add` has no predicate
argument; the three command groups carry it instead — `nil` for the three
persistent commands, `browsing` for fifteen, `searching` for three. That is the
right place for it, and it has one visible consequence: **`Esc` closes the panel
from anywhere in the editor**, because `pluginmanager:close` is one of the
persistent commands with no predicate. <kbd>Ctrl</kbd>+<kbd>R</kbd> is likewise
bound globally, and `treeview:refresh-key` binds the same stroke; whichever
registered later wins while the other's predicate fails.

**The panel and the file tree both claim a pane.** The panel splits
`core.root_view:get_active_node()`, which is whatever you last clicked, and so
does [`treeview`](treeview.md). Whichever loads second takes the layout, and the
result depends on where you had last clicked. The fix — an idempotent
`RootView:attach_side_view` on both, with `config.treeview_side` choosing the
edge — was written and then reverted, because the host API it needs is not there
yet. Until it is, the two of them together are a coin flip.

**The manager never loads what the host loads.** It bootstraps from *inside* the
host's plugin loop, so `core.plugins.loaded` is still missing every entry after
it in the alphabet; it therefore also reads the host's plugin directory. Miss
that and vim gets loaded twice — once with `dofile` here, once with `require`
there — and the second instance collides with the first one's commands.

**Installed extensions are stored without the `X/` prefix**, at
`<extension_dir>/core/treeview/init.lua`, but their own code says
`require "X.core.treeview.treeview_impl"`. `cdinx/manager/loader.lua` is a
`package.searchers` entry that bridges the two — it drops the `X.` and turns the
rest into directories, and sits after the standard Lua searcher so the build's
own copies still win. Without it, every installed extension with more than one
file fails on its first `require`.

**Nothing in this repository registers a registry syncer.**
`Manager.set_registry_syncer` exists, is public, and has no callers; the HTTPS
fetcher is what runs.