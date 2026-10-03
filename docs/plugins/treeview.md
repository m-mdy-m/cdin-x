# treeview

The project file tree. Files, directories, and — with
[`git-treeview`](../../X/integration/git-treeview) installed — git state on them.

| key | does |
| --- | --- |
| <kbd>F2</kbd> | `treeview:toggle-key` — `treeview:toggle` everywhere except the log view, which owns <kbd>F2</kbd> |
| <kbd>Ctrl</kbd>+<kbd>\\</kbd> | `treeview:toggle` — show or hide the tree |
| <kbd>F3</kbd> | `treeview:focus` — move into the tree |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>E</kbd> | `treeview:focus` |
| <kbd>↑</kbd> / <kbd>↓</kbd> | move |
| <kbd>Enter</kbd> / <kbd>Enter</kbd> on the keypad | open the item under the cursor |
| <kbd>←</kbd> | collapse, or jump to the parent |
| <kbd>→</kbd> | expand, or jump into the first child |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>N</kbd> | new file |
| <kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>Shift</kbd>+<kbd>N</kbd> | new directory |
| <kbd>Ctrl</kbd>+<kbd>R</kbd> | rename the selection |
| <kbd>Delete</kbd> | delete the selection |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>R</kbd> | `treeview:refresh-key` |

The arrows, <kbd>Enter</kbd>, <kbd>Ctrl</kbd>+<kbd>R</kbd> and <kbd>Delete</kbd>
are registered globally and work in the tree and in the document. The point is
that you do not have to think about where the cursor is to move around: the
commands behind them check whether the tree has focus, and do nothing when it
does not.

**They act on the selection, not on the cursor row.** <kbd>Ctrl</kbd>-click
toggles an item in, <kbd>Shift</kbd>-click selects a range, and rename and
delete apply to everything selected. With nothing selected both fall back to the
item under the mouse — so <kbd>Delete</kbd> can remove a file you never clicked.

The full command list is `treeview:toggle`, `:toggle-key`, `:focus`,
`:focus-and-refresh`, `:refresh`, `:refresh-key`, `:select-next`,
`:select-previous`, `:expand-or-child`, `:collapse-or-parent`,
`:open-cursor-item`, `:new-file`, `:new-directory`, `:rename`, `:rename-key`,
`:delete`, `:delete-key`, `:toggle-hidden`. Eighteen of them; the comment at the
top of `init.lua` says eighteen.

## In vim mode

With `vim-treeview` installed:

| key | does |
| --- | --- |
| `:tree` / `:trees` | focus the tree and refresh it |

That is the whole of it, and it is worth being precise about why. `vim-treeview`
registers **no keys** — it is two files, and the only thing in them is an
ex-command. The arrows and <kbd>Enter</kbd> you use inside the tree are
`treeview`'s own bindings, and they work in vim mode for a structural reason
rather than a plugin one: when the tree has focus, vim mode is not the thing
handling your keystrokes, so the editor's keymap answers instead.

That is also why <kbd>j</kbd> and <kbd>k</kbd> behave differently depending on
where you are. In a document, vim mode claims them as motions. In the tree,
vim mode is not looking, and the same stroke moves the selection. Nothing
decides this at load time; it falls out of which handler is live.

## Config

| key | default | what it does |
| --- | --- | --- |
| `config.treeview_size` | `200 * SCALE` | the pane's width in cells |
| `config.show_hidden_files` | `true` | whether dotfiles are listed |
| `config.ignore_files` | `"^$"` when hidden files are shown | the pattern the project scanner hides with |

All three are set only when they are `nil`, so a value in your own `init.lua`
wins. Dragging the splitter writes `treeview_size` back — that one is a
deliberate exception.

## Toggling hidden files

`treeview:toggle-hidden` is a command with no key, because there is no obvious
stroke for it and a wrong guess is worse than none. Run it from the palette.

What it does is flip `config.show_hidden_files` and write `config.ignore_files`
to `"^$"` or `"^%.`. **That is a dotfile pattern, not git's answer**, and it
needs no git plugin — the earlier claim that it consulted `.gitignore` was
wrong. The second half matters more: `ignore_files` belongs to the host's
project scanner, not to this plugin, so toggling it also changes what
[`finder`](finder.md) offers and what `search` scans. It is a global switch
wearing a treeview's name.

Hidden files are **shown** by default.

## How it works

```text
treeview_impl.lua      the view: drawing, cursor, badges, the split
tree/build.lua         the scanned file list, shaped into a tree
tree/operations.lua    the selection, the context directory, the refresh
nav.lua                movement, expand, collapse
cache.lua              what is drawn, so a redraw is not a re-walk
readonly.lua           which files are read-only, for the badge
api.lua                the badge/refresh provider registry
commands.lua           every command, and the create/rename/delete operations
keymap.lua             its key bindings
```

**The tree never walks the filesystem.** `tree/build.lua` iterates the host's
already-scanned `core.project_files` and skips collapsed subtrees. So the tree
shows what the project scanner saw — which is why `ignore_files` affects it,
and why a file the scanner has not reached yet does not appear.

**`api.lua` is the registry integrations extend, not the plugin's own API.**
A plugin's public surface here is `core.treeview` — the view instance, set in
`init.lua` and cleared on unload, which is what `git-treeview` reads badges
from. `api.lua` is the *other* direction: `register_badge_provider`,
`register_refresh_provider`, and the `get_badge` / `refresh_providers` functions
the host calls. The distinction matters because it is why `api.lua` and
`init.lua` can be separate files without a second copy of anything: the manager
`dofile`s the entry point to read the manifest, and a plugin whose entry point
*is* its API ends up with two half-initialised copies. See [git](git.md).

**`treeview:refresh-key` and `treeview:refresh` are the same call.**
`refresh-key` performs `treeview:refresh`, which flushes the cache, clears the
read-only table, asks the project scanner for a full rescan, and runs every
refresh provider. There is no per-item refresh in this plugin, despite the two
command names. The read-only-looking key pair is a leftover, and the only cost
is that the name promises something the code does not do.

**`readonly.lua` is a badge, not a guard.** It caches which paths could be
opened for writing, and `Build.is_file_readonly` is read from exactly one place:
drawing the string `RO` next to a row. **No command consults it.** Rename and
delete are not refused on a read-only checkout — they will fail at the `os`
call, and `os.remove`'s return value is not even checked, so a file that could
not be deleted simply disappears from the tree and the UI with no message. If
you want that refusal, it is not here yet.

**`tree/operations.lua` has no filesystem calls in it.** Despite the name, it
holds the selection accessor, the directory a new file should be created in,
and the refresh. Every `mkdir`, `os.rename` and `os.remove` is in
`commands.lua`, next to the command that owns it.

**The badges are ranked, and read-only outranks git.** `status_badge` returns
`"RO"` first, then whatever the badge providers say; providers are sorted by
ascending `order` and the first non-`nil` label wins.

**The arrows are shared with the document on purpose.** Leaving them bound in
both places is what makes the tree feel like part of the editor. It also means
the bindings genuinely have to be removed on unload, because an arrow that
navigated a tree which no longer exists is worse than an arrow that did
nothing — hence `keymap.remove(SHARED)` before `keymap.remove(MAP)`, in that
order, because `SHARED` is the half that joins the runtime's own chain.

**A stroke is spelled, not matched.** The host does not look a keystroke up by
meaning; it *builds* the string it will look up — `ctrl+`, then `alt+`, then
`altgr+`, then `shift+`, then the key's own name — and compares it for
equality. There is no normalisation, so `ctrl+shift+alt+n` is not a variant of
`ctrl+alt+shift+n`: it is a string no key press can produce, and the binding
that used to carry it never fired. New directory is `ctrl+alt+shift+n`, in that
order, because that is the order the host builds modifiers in.
`scripts/validate.lua` now rejects an unreachable stroke at lint time for
exactly this reason.

**<kbd>F2</kbd> belongs to the log view, and the tree yields it.** The log view
is the one place a core key and a plugin key want the same stroke: its header
advertises <kbd>F2</kbd> for switching between the editor's log and the native
one. `log:switch-source` is already scoped to that view, so it declines
everywhere else and wins on the stroke — provided something on the tree's side
declines too, because a stroke is a fallback chain and `keymap.add` prepends.
Hence `treeview:toggle-key`: a command that exists only to give this one
keystroke a predicate, the same trick `rename-key` and `delete-key` use.
`treeview:toggle` itself is untouched, so the palette and every integration can
still toggle the tree from the log view.

**The pane is not removed on unload.** `unload()` clears `core.treeview` and
drops the bindings, but the split it created stays in the layout. Disable the
plugin and you keep an empty column with no key to close it. The fix is not
written.

**The tree is split onto whatever pane is focused.** `treeview_impl.lua` calls
`core.root_view:get_active_node()` and splits there, so where the tree lands
depends on which pane had focus when the plugin loaded. Anything else that
claims a pane the same way — the search results view, the window manager's
teardown — will collide with it, and the winner is decided by load order.

## Files

| file | holds |
| --- | --- |
| `treeview_impl.lua` | the view, the split, the badge drawing |
| `tree/build.lua` | the scanned file list → a tree |
| `tree/operations.lua` | the selection, the context directory, the refresh |
| `nav.lua` | movement and expansion |
| `cache.lua` | what is on screen (LRU, 4096 entries) |
| `readonly.lua` | the read-only cache, for badges |
| `api.lua` | the provider registry integrations extend |