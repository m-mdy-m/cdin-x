# modules

Acting on Lua modules that are already loaded as code.

Three commands, no keys. That is deliberate — reaching them through the
[palette](palette.md) is the point of having a palette, and a chord each would
be a key taken away for nothing.

| command | does |
| --- | --- |
| `core:reload-module` | re-run a loaded module |
| `core:open-user-module` | open your `init.lua` |
| `core:open-project-module` | open `.lite_project.lua`, creating it if absent |

## Reloading

`core:reload-module` calls the runtime's `core.reload_module`, which drops the
name from `package.loaded`, requires it again, and folds the new table's fields
back into the old one — so a table somebody is still holding stays valid rather
than becoming a second, stale copy of itself.

This plugin does not reimplement that. It wraps it, so a module that fails to
require is reported in the log next to the prompt rather than thrown out of the
picker and lost.

**Reloading re-runs a module's top-level code, and nothing else.** Whatever it
registered *while loading* is not undone unless it has an `unload()` of its own.
So a module that registers commands at load time and gets reloaded will collide
with itself: the second pass asserts, or silently doubles, depending on whether
the registration passes `overwrite`. Write the module so its top level is
declarations and its `init()` does the registering, and this stops being a
thing you have to remember.

## The two files it opens

`core:open-user-module` opens `config.user_dir .. "/init.lua"` — your own
configuration, the file that runs before any plugin loads.

`core:open-project-module` opens **`.lite_project.lua`**, and creates it if it
is not there. The name is not chosen here: it is the same literal the runtime
loads at startup, so the command cannot open a different file from the one that
actually runs. The name is a leftover from this editor's fork of lite, and it is
load-bearing — changing it would silently break every existing project file.

## How it works

Three commands of the same shape — offer a list, act on the choice — and each
is small enough that three plugins would be three registration cycles for no
gain.

The project module name is the one thing here worth defending. It could have
been `cdin_project.lua`, and would have read better. It was not, because a
command whose whole job is to open *the* project module must open the file the
runtime opens, and a second spelling of that name is a second answer.

## Files

Single file, `init.lua`.
