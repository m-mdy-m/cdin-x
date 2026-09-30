# session

What survives a restart: recent files, recent directories, the last directory,
and the chosen theme.

| key | does |
| --- | --- |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>R</kbd> | `session:open-recent` |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>D</kbd> | `session:open-recent-dirs` |
| <kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>S</kbd> | `session:save` |
| `session:clear` | forget the recent lists |
| `session:show-info` | where the session file is, and what is in it |

`session:save` is there for the case where you know you are about to lose
something — a crash, a forced quit — and it is bound to a chord you will not
press by accident. You do not normally need it: the session is written on a
clean exit anyway.

`session:show-info` is worth knowing about when something looks wrong. It prints
the file's path and its size, which answers "is it writing at all" in one step.

## Saving on exit

Anything that needs to write something on the way out subscribes rather than
wrapping the exit itself:

```lua
require("X.core.session.api").on_quit(function(force) ... end)
```

`off_quit(fn)` removes a listener.

This exists because one wrapper with many listeners cannot drop a call, and
several wrappers each wrapping the same function can. `tab-session` uses it to
save the open tabs; the extension manager's state file is a different mechanism
entirely. Neither of them patches `core.quit`.

## Themes

`set_theme(name)` records the active theme and **saves immediately**, rather than
waiting for exit. A theme you picked in the middle of a session then survives a
crash, which is the case you would have minded. The persistence itself belongs
to `session-theme-switcher` — this plugin records the choice, that one restores
it, and uninstalling the integration stops the restoring without stopping the
recording.

## <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>D</kbd>

This is bound here *and* in cdin's default keymap, to `doc:duplicate-lines`.
Later registration wins, so this one takes it, and duplicate-lines has to be
reached another way. It is pre-existing behaviour that has been kept rather than
quietly changed underneath anyone, and it is called out here so the next person
to hit it does not spend an hour on it.

## How it works

```text
session/api.lua                    the state, its operations, and the quit listeners
session/commands.lua, keymap.lua   registration only
session/manager/sys.lua            reading and writing the file
session/manager/session-loader.lua applying what was read
```

**The state is published as `core.session`.** Other plugins read it rather than
opening the file themselves. Two readers of the same file would be two answers
to "what were the recent files", and only one of them would be right after a
write.

**The file is written on exit and on demand, never on every change.** Recent
files are a convenience, not a log; writing on every open would mean a disk
write per keystroke-driven action, for a list nobody reads that often.

**Loading is best-effort and silent.** A missing or corrupt session file means
an empty recent list, not an error at startup. A convenience feature that can
prevent the editor from opening has to be the thing that gives way.

## Files

| file | holds |
| --- | --- |
| `api.lua` | the state, its operations, `on_quit` / `off_quit` |
| `commands.lua` | the `session:*` names |
| `keymap.lua` | the three keys above |
| `manager/sys.lua` | reading and writing |
| `manager/session-loader.lua` | applying what was read |
