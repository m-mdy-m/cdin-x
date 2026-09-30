# Installing plugins

You install cdin-x once. After that you install plugins from inside cdin, and
you rarely come back to a terminal.

This page is about the second thing: where a plugin can come from, what the
manager's menu actually does, and what to look at when a plugin you installed
doesn't show up.

## Three places a plugin can be

The manager scans three roots and merges what it finds. Knowing which one a
plugin came from explains most surprises.

| source | where | how it got there |
| --- | --- | --- |
| **builtin** | `<site>/X/` | shipped in this repository, installed by `make link` |
| **installed** | `<data_home>/cdin/extensions/` | you installed it, from the catalog or from a local path |
| **registry** | `<data_home>/cdin/registry/cdin-x/` | a clone of this repository that the manager keeps current |

Later sources win, so an **installed** copy of `treeview` shadows the
**builtin** one, and a **builtin** plugin — `vim` — shadows anything the
registry might also happen to carry. That ordering is the reason a dev checkout
takes precedence without you having to uninstall anything.

A plugin in the registry that isn't installed yet shows up in the catalog but
isn't loaded. That's the normal state for most of what's in here.

## The manager

<kbd>Shift</kbd>+<kbd>M</kbd> anywhere opens it. Vim users get the same panel
from <kbd>m</kbd> then <kbd>X</kbd>, and `cdin-x:menu` runs it from the command
palette.

| key | does |
| --- | --- |
| <kbd>J</kbd> / <kbd>K</kbd> | move |
| <kbd>Space</kbd> or <kbd>X</kbd> | install, or disable/enable if installed |
| <kbd>Enter</kbd> | open the plugin's own menu |
| <kbd>U</kbd> | uninstall |
| <kbd>R</kbd> | open its README |
| <kbd>Ctrl</kbd>+<kbd>R</kbd> | refresh the catalog |
| <kbd>Esc</kbd> | close |

Every action is also a command, so you can bind any of them yourself:

```
cdin-x:menu        pluginmanager:menu      open the manager
cdin-x:catalog     browse and install from the catalog
cdin-x:update      re-fetch what has a newer version
cdin-x:clean       remove extensions the registry no longer carries
cdin-x:refresh     update the catalog itself
```

## Installing one

Pick **Extensions**, move to the plugin, press <kbd>Space</kbd>. It gets copied
into your extension store, loaded, and is live in the same frame. No restart.

If the plugin declares `dependencies`, they install first, in order. A cycle is
reported rather than followed.

**Themes** are the exception to "loaded immediately": the manager installs them
and the host's theme registry picks them up, so a new theme shows up in the
theme switcher rather than becoming a running plugin.

## Installing your own

**Install Local** takes a path to a directory with an `init.lua` in it and
copies it into the same store, exactly as a catalog plugin would be. This is
how you work on a plugin: keep it in your own checkout, install from there, and
re-run **Install Local** after each change.

**Disable** and **Enable** skip installing entirely and just stop the plugin
loading. The choice is remembered across restarts, in
`<data_home>/cdin/extensions.lua` — which is the same file plugin enable/disable
has always used, so it survives an upgrade of this repository.

Note what disable means: a disabled plugin is still *installed*. <kbd>U</kbd>
is what removes it.

## Refreshing

**Refresh Catalog** re-clones the registry. It's a network operation, so it runs
on a coroutine and never blocks the frame loop — the editor stays usable while
it works, and reports when it's done.

**Update All** re-fetches only the plugins whose registry version has moved.
**Clean** offers to remove installed plugins the registry no longer carries,
which is how you get rid of something that was renamed or deleted upstream.

Both talk to the registry, so both need the network. Neither is on any startup
path.

## When a plugin doesn't show up

**It installed, but nothing happened.** The most common cause is a plugin that
registered its commands but not its bindings, or bound keys to a view that
isn't focused. Check its README — a plugin that needs a focused view says so.

**It's not in the catalog at all.** **Refresh Catalog**, and if it's still
missing, it isn't in the registry branch you're pointed at. `config.registry_url`
moves that; so does `CDIN_X_REGISTRY` for the clone location.

**It's in the catalog, but installing fails on a dependency.** The manager
reports which dependency and why. A plugin that depends on something
unreachable from the registry can't be installed as a unit.

**Nothing from this repository loads.** `config.plugins = false` means no *site*
plugins, and this is a site plugin. The bundled set is deliberately not
affected — see
[configuration.md](https://github.com/m-mdy-m/cdin/blob/main/docs/guides/configuration.md)
in the cdin repository.

**The editor didn't start.** It should have. A failing bundled plugin is
reported and skipped, and a failing site plugin is logged and skipped, because
an editor that refuses to open is a worse bug than a missing feature. The
reason is in the log: `core:open-log`, or <kbd>Ctrl</kbd>+<kbd>Shift</kbd>+<kbd>L</kbd>.

## What's in `config`, if you'd rather not use the panel

| key | default | what it does |
| --- | --- | --- |
| `config.plugins` | `nil` | Which site plugins load: `nil` all, `false` none, a table a whitelist. Doesn't touch the bundled set. |
| `config.site_dirname` | `"site"` | The site directory's name, under `<data_home>/cdin/`. |
| `config.site_dir` | unset | A full path, which overrides the name. |
| `config.extension_dir` | `<data_home>/cdin/extensions` | Where installed plugins are copied. |
| `config.registry_dir` | `<data_home>/cdin/registry/cdin-x` | Where the catalog clone lives. `CDIN_X_REGISTRY` overrides. |
| `config.state_file` | `<data_home>/cdin/extensions.lua` | Which plugins you've disabled. |

All of these belong to the host's `config` table and are set in
`~/.config/cdin/user/init.lua`, which runs *before* any plugin loads. A binding
you set there is one a plugin has to override; a binding a plugin sets is one
you can still beat by setting it there.
