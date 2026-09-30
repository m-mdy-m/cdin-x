# tab

Tabs across the top. Open, switch, move, close.

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

`tab:pin` keeps a tab from being taken by `close-others`. `tab:reopen-closed`
brings back the last one you closed, which is a different thing from
`tab:duplicate` and the pair covers most of what people actually want.

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

With `tab-session` installed, `tab:session-save` records the open tabs, and the
next launch offers to bring them back. It is a separate plugin because session
persistence is a separate concern from having tabs: some people want their
tabs and some want a clean slate every morning, and it should not be a
preference buried in the tab plugin's config.

`session` is what actually writes the file, and it writes the theme and the
recent-files list too. Uninstall `session` and tab restoration stops with it.

## How it works

```text
tab/manager.lua        the public surface
tab/manager/index.lua  the ordered list, and which is active
tab/manager/operation.lua  open, close, move, rename, pin
tab/impl.lua           the bar
tab/commands.lua, keymap.lua   registration only
```

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

**`tab:close-force` exists and is not bound to anything.** It is the command
you reach for when `tab:close` refuses because a document is dirty. Having it
findable but unbound is the compromise — a key would be a footgun, and its
absence from the palette would be worse.

## Files

| file | holds |
| --- | --- |
| `manager.lua` | the public surface |
| `manager/index.lua` | the ordered list, and the active one |
| `manager/operation.lua` | open, close, move, rename, pin |
| `impl.lua` | the tab bar |
| `commands.lua` | the `tab:*` names |
| `keymap.lua` | the keys above |
