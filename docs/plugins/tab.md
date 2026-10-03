# tab

Tabs. Open, switch, move, close. There is no tab bar — a `[2/5]` counter
appears on the right of the status bar once you have two or more tabs.

| key | does |
| --- | --- |
| <kbd>Ctrl</kbd>+<kbd>T</kbd> | `tab:new` |
| <kbd>Ctrl</kbd>+<kbd>Tab</kbd> | `tab:next` |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>Tab</kbd> | `tab:prev` |
| <kbd>Ctrl</kbd>+<kbd>1</kbd>…<kbd>9</kbd> | `tab:go-1` … `tab:go-9` |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>PageUp</kbd> / <kbd>PageDown</kbd> | move the tab left / right |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>W</kbd> | `tab:close` |

Everything else is a command: `tab:close-all`, `tab:close-force`,
`tab:close-others`, `tab:duplicate`, `tab:first`, `tab:last`, `tab:pin`,
`tab:rename`, `tab:reopen-closed`.

**`tab:pin` only blocks `tab:close`.** `close-others` and `close-all` pass
`force = true`, and the pin guard tests `pinned and not force` — so pinning is
not a "keep this one" flag and it will not save a tab from either of those.

**`tab:close-all` cannot close the last tab.** The last-tab check runs before
`force` is consulted, so it always leaves exactly one and logs
`tab: cannot close the last tab`.

**`tab:reopen-closed` is lossy.** It restores the name and the views, but not
`pinned`, and it re-inserts at the *end* of the order rather than the position
the tab had. The closed stack holds twenty.

**`tab:duplicate` re-opens the file set, not the layout.** It walks the node
tree by hand to collect filenames and reopens each one, so a split arrangement
does not come back — only the files.

`tab:reopen-closed` and `tab:duplicate` are a different thing from each other,
and the pair covers most of what people actually want.

## In vim mode

With `vim-tab` installed:

| keys | does |
| --- | --- |
| <kbd>g</kbd><kbd>t</kbd> / <kbd>g</kbd><kbd>T</kbd> | next / previous tab |
| <kbd>3</kbd><kbd>g</kbd><kbd>t</kbd> | go to tab 3 — a count in front works |
| <kbd>:</kbd><kbd>tabnew</kbd> <kbd>:</kbd><kbd>tabe</kbd> <kbd>:</kbd><kbd>tabedit</kbd> | new tab, optionally with a path |
| <kbd>:</kbd><kbd>tabclose</kbd> <kbd>:</kbd><kbd>tabc</kbd> | close |
| <kbd>:</kbd><kbd>tabonly</kbd> <kbd>:</kbd><kbd>tabo</kbd> | close the others |
| <kbd>:</kbd><kbd>tabnext</kbd> <kbd>:</kbd><kbd>tabn</kbd> | next, or tab N |
| <kbd>:</kbd><kbd>tabprevious</kbd> <kbd>:</kbd><kbd>tabp</kbd> | previous |
| <kbd>:</kbd><kbd>tabfirst</kbd> <kbd>:</kbd><kbd>tabr</kbd> | first |
| <kbd>:</kbd><kbd>tablast</kbd> | last |
| <kbd>:</kbd><kbd>tabmove</kbd> <kbd>:</kbd><kbd>tabm</kbd> | move to position N |

`:tabnew` and `:tabedit` take an optional path, and the `:` line offers path
completion for them — which is the `arg_paths` flag on a registry spec doing
its job.

## Restoring tabs across a restart

With `tab-session` installed, `tab:session-save` records the open tabs. It is a
separate plugin because session persistence is a separate concern from having
tabs: some people want their tabs and some want a clean slate every morning, and
it should not be a preference buried in the tab plugin's config.

**Restoring is off by default.** `config.tab_session_restore` defaults to
`false`, so nothing comes back until you set it. When it is on, it restores
**files only** — not the split layout — and it does so silently in a thread on
launch, with no prompt.

`session` does **not** write this file. `tab-session` has its own writer, its own
path (`<data>/cdin/tab_session.lua`, hard-coded rather than derived from
`config.data_dir`), and its own `on_quit` subscription. What it takes from
`session` is the quit seam — and with `session` uninstalled, tab saving stops
even though the integration is still installed.

## How it works

```text
tab/manager.lua        the public surface
tab/manager/index.lua  the ordered list, and which is active
tab/manager/operation.lua  open, close, move, rename, pin
tab/impl.lua           the status-bar counter, and registration
tab/commands.lua, keymap.lua   registration only
```

**The counter is a patch on `StatusView.get_items`, not a widget.** `impl.lua`
saves the original, appends a dim `[n/total]` cluster to the right of the status
bar when there are two or more tabs, and puts the original back on unload. It is
not a tab bar and it draws nothing else.

**`manager/index.lua` reaches three levels into the host's node tree** —
`root.b.a`, then `.b` and `.a` — looking for an unlocked pane to restore a tab
into. That is this plugin's tightest coupling to the host's layout and the most
likely thing to break if the host restructures; nothing in the catalog checks it.

**Tabs are an index over view trees, not copies of anything.** Switching tabs
moves the root view's active child; it does not rebuild anything. That is why
switching is instant regardless of how many documents are open, and why a tab
can hold a whole split layout without either plugin knowing about the other.

**`manager/index.lua` owns the order, and nothing else does.** `operation.lua`
asks it to move and close. Two modules each keeping their own idea of which tab
is third is how a tab bar ends up disagreeing with what <kbd>g</kbd><kbd>t</kbd>
does.

**The <kbd>Ctrl</kbd>+<kbd>1</kbd>…<kbd>9</kbd> bindings are written out, one
line each.** They could be a loop, and probably should be — nine copies of one
line is nine places for a typo, and a plugin that has a `manager/index.lua` for
the sake of tidiness has no excuse here. It is listed because it is the sort of
thing you notice when you go looking for `tab:go-10`, which does not exist and
cannot without a stroke you have not got.

**A count in front of <kbd>g</kbd><kbd>t</kbd> is handled by vim mode, not by
the tab plugin.** `registry.call_gmap("gt", n)` passes the count through, and
`vim-tab` decides what to do with it. Vim core never learns that `t` means
"tab"; it learns that `g` starts a sequence and hands over the rest.

**`tab:close` never refuses because of a dirty document.** This plugin does not
inspect documents at all. Its only refusal is the pin message
`tab: '<name>' is pinned — unpin first or use force`. So `tab:close-force` is not
"close the dirty one anyway" — it is the same command with the pin check
skipped, and it is unbound because there is nothing else it would be for.

**There is a one-frame window before tabs exist.** `bootstrap()` runs in a thread
after a `coroutine.yield(0)`, so for one frame `tab_order` is empty and every
navigation command is a silent no-op.

## Files

| file | holds |
| --- | --- |
| `manager.lua` | the public surface |
| `manager/index.lua` | the ordered list, and the active one |
| `manager/operation.lua` | open, close, move, rename, pin |
| `impl.lua` | the status-bar counter, and registration |
| `commands.lua` | the `tab:*` names |
| `keymap.lua` | the keys above |
