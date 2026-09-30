# modules

Acting on Lua modules that are already loaded as code.

| command | does |
| --- | --- |
| `core:reload-module` | re-run a loaded module |
| `core:open-user-module` | open your `init.lua` |
| `core:open-project-module` | open `.lite_project.lua`, creating it if absent |

No key bindings. These are three deliberate, occasional actions, and reaching
them through the command palette is the point of having a palette — a chord
each is a key taken away for nothing.

`core:open-project-module` opens the same file the runtime loads at startup,
so the command cannot show you a different file from the one that actually
runs. `core:reload-module` wraps the runtime's `core.reload_module` rather than
reimplementing it, so a module that fails to require is reported in the log
next to the prompt instead of thrown out of it.

Reloading re-runs a module's top-level code only. Whatever it registered while
loading is not undone unless it has an `unload()` of its own, so a module that
registers commands and gets reloaded will collide with itself.

**Full page:** [modules — what it does, what you press, and how it works](../../../docs/plugins/modules.md)
