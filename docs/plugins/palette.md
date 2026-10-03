# palette

Every command the editor has, by name. <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>.

Type a fragment, move with the arrows, <kbd>Enter</kbd> to run it. It is the same
prompt [menu](menu.md) is built from, which is why the keystrokes are the same.

## Why it is a plugin

Because the editor has no command palette of its own, and having the mechanism
without the thing is the useful state.

`core.command_view` — the prompt, its suggestion list, and the selection — is a
runtime service, always present. What you do with it is a choice. The palette,
the file finder, the project-folder prompt, the git commit message, the
extension manager: all of them are the same prompt with different text in it,
and all of them are plugins.

So: **if you have not installed this, <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>
does nothing.** Nothing is lost — every command it would have listed is still
reachable, by key or by whichever plugin bound it. You just have to know the
names.

## Reading the list

**It is fuzzy.** A non-contiguous subsequence match, so `fnf` finds
*core: find file*. That is `common.fuzzy_match`, and it is a stronger
match than [menu](menu.md)'s, which is a plain substring — the menu has
letter shortcuts and a small list, so exactness costs nothing there.

**The list is read when the palette opens**, not when the plugin loads. Install a
plugin and its commands are in the palette immediately; disable one and they are
gone immediately. No restart either way.

**Only commands you could actually run right now are listed.**
`command.get_all_valid()` evaluates each command's predicate and omits the ones
that do not hold — so a command whose predicate does not hold is not listed at all.
Hiding it is the honest choice: the alternative is a list that offers you
something and then refuses, which is worse than a shorter list.

**Names are flattened for reading.** `treeview:new-file` shows as *treeview: new
file*, which is `command.prettify_name`. You do not have to know the convention
to read the list.

**The right-hand column is the keystroke**, when there is one. So the palette
doubles as the keymap reference you did not have to memorise — and a command
with an empty column is one nobody bound, which is the quickest way to find
your own unbound commands.

## How it works

```lua
local command = require "core.input.command"

command.get_all_valid()   -- the names whose predicate holds right now
command.perform(name)     -- run one
command.prettify_name(n)  -- "treeview:new-file" -> "treeview: new file"
```

**`get_all_valid()` walks the registry on every call.** The command table is
mutated by plugins loading and unloading at runtime, and a palette that
snapshotted it at open time would offer commands that no longer exist. That is
the whole reason the palette is a loop over the registry rather than a table of
its own.

**It reads the registry; it owns nothing.** Which is why installing it changes
nothing about how commands work, and why a plugin is reachable by palette even
when the palette is not what bound it.

**The keystroke is added and removed as a pair.** `keymap.add(KEYS)` and
`keymap.remove(KEYS)` with the same table. A <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>P</kbd>
left bound to a command that no longer exists is a dead key indistinguishable
from a broken editor, so this is not optional bookkeeping.

**It registers a help entry, and keeps the handle.** The empty view's quick
reference lists the keystroke without the runtime hardcoding it — see
[the note in `writing-a-plugin.md`](../writing-a-plugin.md) about `register_help_shortcuts`.
The handle is handed back in `unload()`, because a plugin that does not keep it
cannot clean up after itself, and a reload then advertises the shortcut twice.

**`M.config.show_keybinds` controls the right-hand column, and you cannot
change it.** It is read from the plugin's own table, not from the host's
`config`, so there is no `init.lua` line that reaches it. That is worth knowing
if you were about to go looking for one, and it is the same shape of mistake as
a plugin declaring `vim_mode_enabled` and never applying it: a default in the
wrong table reads exactly like a setting.

## Files

Single file, `init.lua`.
