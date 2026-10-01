# Manager

The panel: what is installed, what is available, and what you can change.
Bundled into every build, so it is a keystroke away whether or not anything
else is.

## Keys

| key | does |
| --- | --- |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>M</kbd> | open / close |
| <kbd>M</kbd> | the same, in vim normal mode |
| <kbd>J</kbd> / <kbd>K</kbd>, <kbd>↓</kbd> / <kbd>↑</kbd> | move |
| <kbd>/</kbd> or <kbd>Ctrl</kbd>+<kbd>F</kbd> | search |
| <kbd>Space</kbd> / <kbd>Return</kbd> | enable or disable |
| <kbd>I</kbd> | install |
| <kbd>U</kbd> | remove |
| <kbd>D</kbd> | details: README, update, lock, remove |
| <kbd>R</kbd> | rescan what is on disk |
| <kbd>Ctrl</kbd>+<kbd>R</kbd> | re-download the catalog index (one file, no git) |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>L</kbd> | open the log |
| <kbd>[</kbd> / <kbd>]</kbd> | narrower / wider |
| <kbd>Esc</kbd> | close |

**Two modes.** While browsing, letters are commands and the footer says so.
Press <kbd>/</kbd> and every printable key goes into the query instead, including
the ones bound above — because typing `j` has to produce a `j`, or a filter over
a list of extensions cannot contain most of the alphabet. <kbd>Backspace</kbd>
deletes, <kbd>Return</kbd> keeps the filter and puts the cursor on the best
match, <kbd>Esc</kbd> leaves the search and leaves the filter.

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

## Search

Substring over the name, the description and the category first — that is what
"find me the one about trees" means, and it is exact. Fuzzy over the name
second, so `tv` still finds `treeview`. Never the other way round: a fuzzy
match that quietly returns things you did not ask for is worse than a miss.

With a query, the best match is ranked to the top within its category rather
than sorted alphabetically, and the header says how many of how many matched.

## What it can install

What is on disk. Installing means copying files that have to exist somewhere,
and the catalog is a list of paths:

| you have | the panel offers |
| --- | --- |
| a cdin build | the set the build ships, and nothing installable |
| cdin-x installed into the site directory | the whole catalog, installable |
| a registry on disk (`CDIN_X_REGISTRY`) | the registry's catalog, and a git extension to refresh it |

**The network, and how little of it.** Opening the panel the first time downloads
one file, the index. Search reads only that. Installing downloads only the
files of the extension you picked. Nothing is cloned.

## What persists

Enable and disable, in this repository's own state file
(`<data_home>/cdin/extensions.lua`), keyed by extension name. The runtime keeps
no registry of its own, and nothing here writes to a cdin checkout.

## Layout

| file | holds |
| --- | --- |
| `cdinx/panel/init.lua` | builds the view, registers commands and keys |
| `cdinx/panel/view.lua` | the view: rows, cursor, scrolling, drawing |
| `cdinx/panel/rows.lua` | catalog → rows. Pure |
| `cdinx/panel/search.lua` | what a query matches. Pure |
| `cdinx/panel/commands.lua` | every command, with the predicate that gates it |
| `cdinx/panel/keymap.lua` | the keys, in three maps |

The two pure modules take plain data and answer it, which is why
`make test-panel` and `make test-panel-view` can check them with no window, no
build and no cdin.

## How it works

`cdinx/init.lua` bootstraps three things in order: scan the catalog, load what is
enabled, then build the panel. The panel is required last, because everything it
lists is something the first two put there.

The panel is a **locked split** — its own pane on the right of the active one,
holding its width whether open or shut. A view added and removed on each open
would take the pane's tabs with it and resize the document every time.

**Two rules worth knowing about, because both were bugs.**

Every key is behind a view predicate. A panel that binds its keys unconditionally
takes over the editor's: `ctrl+r` refreshing a catalog from inside a log view,
`space` toggling an extension from anywhere, no error and nothing on screen to
explain it.

And the manager never loads what the host loads. It bootstraps from *inside* the
host's plugin loop, so `core.plugins.loaded` is still missing every entry after
it in the alphabet; it therefore also reads the host's plugin directory. Miss
that and vim gets loaded twice — once with `dofile` here, once with `require`
there — and the second instance collides with the first one's commands.
