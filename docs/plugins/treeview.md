# treeview

The project file tree, down the left. Files, directories, and — with
[`git-treeview`](../../X/integration/git-treeview) installed — git state on them.

| key | does |
| --- | --- |
| <kbd>F2</kbd> or <kbd>Ctrl</kbd>+<kbd>\</kbd> | `treeview:toggle` — show or hide the tree |
| <kbd>F3</kbd> or <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>E</kbd> | `treeview:focus` — move into the tree |
| <kbd>↑</kbd> / <kbd>↓</kbd> | move |
| <kbd>Enter</kbd> | open the item under the cursor |
| <kbd>←</kbd> | collapse, or jump to the parent |
| <kbd>→</kbd> | expand, or jump into the first child |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>N</kbd> | new file |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>Alt</kbd>+<kbd>N</kbd> | new directory |
| <kbd>Ctrl</kbd>+<kbd>R</kbd> | rename the item under the cursor |
| <kbd>Delete</kbd> | delete it |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>R</kbd> | refresh this item only |

The arrows and <kbd>Enter</kbd> work in both the tree and the document, which is
the point: you do not have to think about where the cursor is to move around.
The commands behind them check whether the tree has focus, and do nothing when
it does not.

The full command list is `treeview:toggle`, `:focus`, `:focus-and-refresh`,
`:refresh`, `:refresh-key`, `:select-next`, `:select-previous`,
`:expand-or-child`, `:collapse-or-parent`, `:open-cursor-item`, `:new-file`,
`:new-directory`, `:rename`, `:rename-key`, `:delete`, `:delete-key`,
`:toggle-hidden`.

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

## Toggling hidden files

`treeview:toggle-hidden` is a command with no key, because there is no obvious
stroke for it and a wrong guess is worse than none. Run it from the palette.

What counts as hidden is git's answer, not a dotfile check — see
[git](git.md). With no git plugin installed there is no ignore information and
the toggle does nothing, which is a quieter failure than guessing `.*` and
being wrong about `.github`.

## How it works

```text
treeview/treeview_impl.lua   the view itself
treeview/tree/build.lua      walking the directory into a tree
treeview/tree/operations.lua rename, delete, mkdir
treeview/nav.lua             movement, expand, collapse
treeview/cache.lua           what is on screen, so a redraw is not a re-walk
treeview/readonly.lua        refusing the operations a read-only project forbids
treeview/api.lua             the public surface
```

**The tree is a cache, not a view of the filesystem.** `cache.lua` holds what is
drawn, and `refresh-key` re-reads one item rather than the whole tree. That is
what makes refreshing a 10,000-file project not a pause, and it is why
`treeview:refresh` (everything) and `treeview:refresh-key` (one item) are
separate commands.

**`api.lua`, not `init.lua`.** The manager `dofile`s the entry point, and a
plugin whose entry point is also its API ends up with two half-initialised
copies. Every plugin that has a public surface keeps it in a separate file. See
[git](git.md) for the full explanation — it is the one structural rule with no
`validate` check behind it.

**`readonly.lua` is a separate file because the failure it prevents is loud.**
Renaming a file in a read-only checkout would otherwise appear to work and then
fail on write, having already moved the tree's idea of where the file is. The
refusal happens before the operation, not after.

**The arrows are shared with the document on purpose.** Leaving them bound in
both places is what makes the tree feel like part of the editor. It also means
the bindings genuinely have to be removed on unload, because an arrow that
navigated a tree which no longer exists is worse than an arrow that did
nothing. Hence the explicit `keymap.remove(MAP)` and the comment at the top of
`keymap.lua` saying why it is not optional.

**Git badges come from `git-treeview`, not from here.** This plugin knows about
files. The integration knows about the tree *and* about git, and it refreshes
the tree when `cwd_changed` fires. Uninstall it and the badges go; the tree
stays.

## Files

| file | holds |
| --- | --- |
| `treeview_impl.lua` | the view |
| `tree/build.lua` | directory → tree |
| `tree/operations.lua` | create, rename, delete |
| `nav.lua` | movement and expansion |
| `cache.lua` | what is on screen |
| `readonly.lua` | refusing what cannot be written |
| `api.lua` | the public surface |
