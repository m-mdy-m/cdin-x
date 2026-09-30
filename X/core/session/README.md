# session

What survives a restart: recent files, recent directories, the last directory,
and the chosen theme. The state is published as `core.session`.

`api.lua` holds the state and its operations, `commands.lua` and `keymap.lua`
the bindings, and `manager/` reads and writes the file.

## The seam

Anything that needs to persist on exit subscribes rather than wrapping
`core.quit` itself:

```lua
require("X.core.session.api").on_quit(function(force) ... end)
```

`off_quit(fn)` removes a listener. One wrapper, many listeners, and no risk of
a dropped call when the second wrapper has a bug — which is the reason this
exists rather than each plugin saving on the way out.

`set_theme(name)` saves immediately rather than at exit, so a choice made
mid-session survives a crash.

`session:*` commands are `open-recent`, `open-recent-dirs`, `save`, `clear` and
`show-info`. <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>D</kbd> is bound here *and* in
cdin's default keymap, to `doc:duplicate-lines`; later registration wins, so
this one takes it. Pre-existing behaviour, kept rather than silently changed.

**Full page:** [session — what it does, what you press, and how it works](../../../docs/plugins/session.md)
