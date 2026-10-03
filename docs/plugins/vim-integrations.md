# The vim integrations

`vim` knows how to edit. It does not know what a tab is, or a file tree, or a
repository. Ten small plugins fill that gap — seven `vim-*`, and three that are not about vim mode at all, and each one is separately
installable, separately removable, and does exactly one thing.

## The table

| install this | you get |
| --- | --- |
| `vim-menu` | <kbd>m</kbd> — the Files / Navigate / Build / Shell menu |
| `vim-window` | <kbd>Ctrl</kbd>+<kbd>W</kbd> and <kbd>Tab</kbd>, plus `:split` and friends |
| `vim-tab` | <kbd>g</kbd><kbd>t</kbd>, <kbd>g</kbd><kbd>T</kbd>, and `:tabnew` and friends |
| `vim-search` | <kbd>/</kbd> <kbd>n</kbd> <kbd>N</kbd> <kbd>*</kbd> |
| `vim-treeview` | `:tree` |
| `vim-git` | git commands, and the Git section in the menu |
| `vim-plugin-manager` | <kbd>M</kbd> — the extension manager |

Plus three that are not about vim mode at all:

| install this | you get |
| --- | --- |
| `git-treeview` | git badges in the file tree |
| `tab-session` | `tab:session-save`, and restoring tabs on launch |
| `session-theme-switcher` | your chosen theme survives a restart |

## The important one: what happens when you remove one

**Nothing breaks.** This is the property the whole arrangement exists for, and
it is worth testing once, on a plugin you do not care about.

Uninstall `vim-tab` and <kbd>g</kbd><kbd>t</kbd> does nothing, because `vim-tab`
is what registered it. The `tab` plugin keeps working — you still have
<kbd>Ctrl</kbd>+<kbd>T</kbd> and <kbd>Ctrl</kbd>+<kbd>Tab</kbd>. `:tabnew`
disappears from `:help`, because `:help` lists what is registered right now.

Contrast that with the alternative, which is what vim mode would look like if it
owned its own keys: uninstall the tab plugin and `:tabnew` is still there,
typed into your muscle memory, silently doing nothing. You would spend an
afternoon on that. This design makes it impossible, at the cost of vim mode
having to be told about things by other plugins — which is what
[the registry](../extending-vim.md) is for.

## Details

### vim-menu

<kbd>m</kbd>, and `vim-fmenu:open` / `vim-menu:open` if you want a different
key. Sections: **Files**, **Navigate**, **Build**, **Shell**. See
[menu](menu.md).

The Git and CDIN-X sections are added by `vim-git` and `vim-plugin-manager`, not
by this one. That is visible in a good way: with those uninstalled, the menu
opens and simply has fewer sections.

### vim-window

<kbd>Ctrl</kbd>+<kbd>W</kbd> then a character, exactly as in vim — <kbd>v</kbd>,
<kbd>s</kbd>, <kbd>o</kbd>, <kbd>c</kbd>, <kbd>n</kbd>, <kbd>p</kbd>,
<kbd>h</kbd> <kbd>j</kbd> <kbd>k</kbd> <kbd>l</kbd>, <kbd>=</kbd>, <kbd>&gt;</kbd>,
<kbd>&lt;</kbd>. Also <kbd>Tab</kbd> for the next pane, and `:split` / `:vsplit` /
`:vnew` / `:close` / `:only` from the `:` line.

<kbd>Tab</kbd> is the one that is not vim — it is what <kbd>Tab</kbd> does in
every other editor. It is consulted only after vim's own keys decline, so it
cannot shadow one.

### vim-tab

<kbd>g</kbd><kbd>t</kbd> and <kbd>g</kbd><kbd>T</kbd>, with a count in front
(<kbd>3</kbd><kbd>g</kbd><kbd>t</kbd>). From the line: `:tabnew` `:tabe`
`:tabedit` `:tabclose` `:tabc` `:tabonly` `:tabo` `:tabnext` `:tabn`
`:tabprevious` `:tabp` `:tabfirst` `:tabr` `:tablast` `:tabmove` `:tabm`.

`:tabnew` and `:tabedit` take an optional path, and the `:` line offers path
completion for them.

### vim-search

<kbd>/</kbd> to search, <kbd>n</kbd> to repeat, <kbd>N</kbd> to repeat
backwards, <kbd>*</kbd> for the word under the cursor.

<kbd>*</kbd> with no word under the cursor deliberately does nothing rather than
opening an empty search — a key that opens a prompt you have to dismiss is
worse than a key that does nothing.

### vim-treeview

`:tree` and `:trees`, and that is not the whole plugin. It also subscribes to
vim's `cwd_changed` event so `:cd` refreshes the tree, contributes the menu's
only **context provider** (priority 200, which is why the menu title shows the
tree's state), and adds the **Tree** menu section — focus, refresh, toggle
hidden, reveal — at order 20, ahead of everything else.

It registers no vim keys at all. The arrows and `Enter` you use inside the tree
belong to [`treeview`](treeview.md), and they work in vim mode for a structural
reason: when the tree has focus, vim mode is not the thing handling your
keystrokes.

The arrows and <kbd>Enter</kbd> work inside the tree without this plugin,
because they are `treeview`'s own bindings and the tree has focus — so vim mode
is not the thing handling your keystrokes. Nothing here decides that; it falls
out of which handler is live.

### vim-git

`vim-git:status`, `:log`, `:diff`, `:add-all`, and the `vim-shell:git-status` /
`git-log` / `git-diff` aliases. All output to the scratch buffer, the same one
`:!make` writes to.

It also adds the **Git** section to the menu — Status, Log, Diff, Add All,
Commit, Push, Pull, Branches — and Commit asks for a message first, because
`git commit` with no `-m` would sit in the buffer waiting for input that cannot
reach it.

### vim-plugin-manager

<kbd>M</kbd>, which opens the extension manager panel, and adds the **CDIN-X**
section to the menu. <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>M</kbd> does the same thing without
vim mode, so the panel is reachable either way.

## Why these are `integration/` and not `core/`

Because a `X/core/` plugin may not depend on another X plugin, and all seven `vim-*` of
these depend on two: `vim`, and the capability they are wiring.

`vim-search` is the clearest illustration. It depends on `vim` and on `search`,
and it is the only file in the repository that mentions both. Remove
`X/integration/vim/vim-search/` and `search` still works, `vim` still works, and
neither of them has a hole where the integration was. Keep it and `/` works.

If `/` were implemented inside `X/core/search/`, that plugin would require
`X/core/vim` — and the day you decided to ship cdin without vim mode, search
would either break or grow a second code path that nobody tests.

## How they register

Every one of them goes through `X.core.vim.registry`, which has seven seams:

| seam | used by |
| --- | --- |
| `register_command(spec)` | vim-tab, vim-window, vim-treeview |
| `register_key(map)` | vim-menu (`m`), vim-search (`/ n N *`), vim-window (`Tab`), vim-plugin-manager (`M`) |
| `register_gmap(map)` | vim-tab (`gt`, `gT`) |
| `register_wmap(map)` | vim-window (the <kbd>Ctrl</kbd>+<kbd>W</kbd> characters, and `:wincmd`) |
| `register_visual_key(map)` | nothing yet |
| `register_action(id, fn)` | nothing yet |
| `on(event, fn)` | one event exists: `cwd_changed`, emitted by `:cd` and used by `vim-treeview` |

[docs/extending-vim.md](../extending-vim.md) has the details and a worked
example.

## The dependency rule, because it is the thing that bites

```lua
dependencies = { "vim", "menu", "vim-menu" }
```

If your integration extends a menu, declare the integration that **defines**
that menu. `menu` is the capability that knows how to define and open a menu;
`vim-menu` is what defines `vim.main` specifically. Declaring only the first is
the mistake that produces:

```
menu is not defined: vim.main
```

…on some runs and not others, because the catalog is scanned with `pairs()` and
load order is not stable. `make validate` checks every cross-plugin `require`
and every menu extension against your declarations, so it fails the build rather
than failing at somebody's keyboard.
