# autoupdate

Asks whether there is a newer cdin, and badges the status bar until you
dismiss it.

| key | does |
| --- | --- |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>U</kbd> | `autoupdate:check` |
| — | `autoupdate:skip-version` — never tell me about this version again |

`autoupdate:skip-version` has no key on purpose. It is a decision you make once
per release, and a key you can hit by accident while dismissing a badge is a
key that will be.

## What it does and does not do

**It checks. It does not install.** There is no "download and replace your
editor" here, and there is not going to be: an editor that can replace its own
binary is an editor where running a plugin is a much smaller step than it looks,
and that is not a trade this project should make silently. If you want a new
version, you get a new version the way you got this one.

**It is a network round trip, so it is on a coroutine.** Nothing blocks, and
the editor is fully usable while it happens. If it fails — no network, a rate
limit, a firewall — it says so and stops. It does not retry in a loop.

**It does not run at startup.** The check is something you ask for, or something
you schedule yourself in `init.lua`. An editor that phones home before you have
seen it is an editor that is training you to expect that of editors.

## Scheduling it yourself

```lua
-- ~/.config/cdin/user/init.lua
core.add_thread(function()
  while true do
    coroutine.yield(60 * 60 * 24)     -- once a day
    require("core.input.command").perform("autoupdate:check")
  end
end)
```

`core.add_thread` is the runtime's coroutine helper, and `coroutine.yield` with
a number sleeps. This is the same mechanism every plugin here uses for anything
that must not block the frame loop.

## How it works

```text
autoupdate/manager/fetcher.lua   the network call
autoupdate/manager/utils.lua     shared helpers
autoupdate/impl.lua              the badge and its dismissal
autoupdate/commands.lua, keymap.lua   registration only
```

**The badge is a status pill, not a drawn thing.** It goes in through
`core.register_status_pill(key, provider)`, like the vim mode indicator, and
returns `nil` when there is nothing to say. So it disappears by returning nil —
there is no "hide the pill" call to forget.

**Dismissal is remembered per version, not per check.** Otherwise a badge you
dismissed comes back on the next launch, and the only way to stop it is to
uninstall the plugin — which is a much larger action than "not now".

## Files

| file | holds |
| --- | --- |
| `manager/fetcher.lua` | the network call |
| `manager/utils.lua` | shared helpers |
| `impl.lua` | the badge, and its dismissal |
| `commands.lua`, `keymap.lua` | registration |
