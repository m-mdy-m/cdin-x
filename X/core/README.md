# core

One capability per directory. The finder, the project tree, tabs, search, git,
the command palette, the menu primitive, and vim mode.

A plugin here may not depend on another X plugin. Not *prefer* to — may not,
at all. If two of these genuinely need each other, the wiring belongs in
[`../integration/`](../integration), which declares the dependency so the
manager can order the load.

The alternative is a plugin that works right up until somebody uninstalls the
other one, and a catalog nobody can reason about. `make validate` fails the
build rather than letting that happen.

`vim` is the one exception to "optional", and not because of where it lives:
it's the only plugin marked `essential = true`, which means a cdin build cannot
start without it and copies it in. Being essential also makes it
self-contained — every `require "X.…"` inside it has to resolve within its own
subtree, because it is bundled alone.

Details: [docs/writing-a-plugin.md](../../docs/writing-a-plugin.md).
