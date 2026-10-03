# autoupdate

Asks whether there is a newer cdin, and badges the status bar until you
dismiss it.

| key | does |
| --- | --- |
| <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>U</kbd> | `autoupdate:check` |
| — | `autoupdate:skip-version` — hide the badge for this session |

`autoupdate:skip-version` has no key on purpose. It is a decision you make
once, after you have read what the badge said, and there is nothing to hit by
accident: the badge is three cells of text in the status bar, not a button.

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
autoupdate/manager/utils.lua     version comparison, platform split
autoupdate/impl.lua              the badge and its dismissal
autoupdate/commands.lua          registration only
autoupdate/keymap.lua            registration only
```

**The badge is a wrapper around `StatusView.get_items`.** It saves the original,
and splices three cells onto the *front* of the right-hand group — `style.text`,
`" ↑ v<version> available "`, `style.dim`. It is not
`core.register_status_pill`, which is the other way into that bar and the one the
vim mode indicator uses; the difference matters on unload, below.

**So it is removed by putting the original back.** `impl.remove_badge()` assigns
`StatusView.get_items = original_get_items` again, and `unload()` calls it. The
alternative — a pill that returns `nil` when there is nothing to say — needs no
uninstall at all, which is why the wrapper would have been the wrong shape if
`remove_badge` did not exist. It does exist, and it is guarded by
`badge_installed`, because the version of this that restored itself on dismissal
stacked one wrapper per check: dismiss, check, dismiss, and each layer captured
the layer below it, so nothing could be undone on the way out.

**Dismissal is one boolean, for this session.** `impl.badge_dismissed` is set to
`true` and read by the wrapper on every status-bar repaint. It is not keyed by
version, and it is not written to disk — there is no state file and no
`config` key, so the badge is back on the next launch and there is no way to
un-dismiss it without restarting. A key named `skip-version` that skips exactly
one version would need both; it does not have both, and the name is the thing
that is wrong rather than the behaviour.

**The badge text is fixed at the first check.** `install_badge(latest)` closes
over the version it was handed, and the `badge_installed` guard means a second
check that finds a *newer* release does not install a second badge. So if you
check twice in a session and a build lands in between, the bar still shows the
version from the first check. `autoupdate:check` still logs the newer one.

**Two downloaders, and only one of them has a timeout.** POSIX shells out to
`curl -sf --max-time 10` against
`api.github.com/repos/m-mdy-m/cdin/releases/latest`; Windows uses
`powershell -NoProfile -NonInteractive -Command (Invoke-WebRequest …)` with no
timeout at all. Both go through `pcall(io.popen, …)` and empty output reads as
failure, so the worst case on Windows is a check that takes as long as the
network takes to give up.

**Version comparison is integers only.** `version_gt` pulls every run of digits
out of both strings and compares them numerically, so `1.2.0-alpha` compares
equal to `1.2.0` — a pre-release of a newer version reads as the release
itself, and is not offered.

## Files

| file | holds |
| --- | --- |
| `manager/fetcher.lua` | the network call |
| `manager/utils.lua` | version comparison, the platform split |
| `impl.lua` | the badge, and its dismissal |