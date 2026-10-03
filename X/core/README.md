# core

One capability per entry. Sixteen of them: `autocomplete`, `autoreload`,
`autoupdate`, `finder`, `git`, `manager`, `menu`, `modules`, `palette`,
`search`, `session`, `tab`, `treeview`, `trimwhitespace`, `vim`, `window`.
Most are a directory; `autoreload` and `trimwhitespace` are a single `.lua`
file, and the directories of those same names hold nothing but their README.

A plugin here may not depend on another X plugin. Not *prefer* to — may not,
at all. If two of these genuinely need each other, the wiring belongs in
[`../integration/`](../integration), which declares the dependency so the
manager can order the load.

The alternative is a plugin that works right up until somebody uninstalls the
other one, and a catalog nobody can reason about. `make validate` fails the
build rather than letting that happen.

**Two are `essential = true`**: `vim`, and `manager` — the extension panel.
Both are copied into every cdin build, which means a build with nothing else
installed can still be told what is installed and change it. Everything the
manager *offers* stays optional; what is not optional is being able to ask.

Being essential also makes a plugin **self-contained** — every
`require "X.…"` inside it has to resolve within its own subtree, because it is
bundled alone. `manager` is the exception that proves why the rule needs
stating: its code lives at the checkout root, not under `X/`, so it declares
`bundle_with = { "cdinx" }` and the bundler copies that path in beside it.

Details: [docs/writing-a-plugin.md](../../docs/writing-a-plugin.md).
