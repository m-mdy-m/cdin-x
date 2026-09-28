# session

Persists state between runs: recent files, recent directories, the last
directory, and the chosen theme.

## Layout

| file | role |
|---|---|
| `api.lua` | the state and its operations; published as `core.session` |
| `commands.lua` | `session:*` commands |
| `keymap.lua` | Ctrl+Shift+R / Ctrl+Shift+D / Ctrl+Alt+S |
| `manager/sys.lua` | reading and writing the session file |
| `manager/session-loader.lua` | loading helpers |

## Extension seam

`session` is essential, so it always loads and therefore owns the **single**
wrap of `core.quit` for the whole X layer. Anything that needs to persist on
exit subscribes instead of wrapping `core.quit` a second time — one
wrapper, many listeners, and no risk of a dropped call if a second wrapper
has a bug:

```lua
require("X.core.session.api").on_quit(function(force) ... end)
```

`off_quit(fn)` removes a listener again.

`set_theme(name)` records the active theme and saves immediately, so a
choice made mid-session survives a crash rather than only a clean exit.

## Note on Ctrl+Shift+D

`ctrl+shift+d` is bound here and also in cdin's default keymap, to
`doc:duplicate-lines`. Later registrations win, so this one takes it and
duplicate-lines has to be reached another way. This is pre-existing
behaviour, kept rather than silently changed.

## Commands

`session:open-recent`, `session:open-recent-dirs`, `session:save`,
`session:clear`, `session:show-info`
