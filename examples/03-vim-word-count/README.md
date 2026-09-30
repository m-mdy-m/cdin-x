# vim-word-count

`:wordcount` and <kbd>g</kbd><kbd>c</kbd> in vim mode, counting the current
buffer.

## Try it

```sh
cd <site>
cp -r /path/to/examples/03-vim-word-count vim-word-count
```

<kbd>Shift</kbd>+<kbd>M</kbd> → **Install Local** → `<site>/vim-word-count`.

The `vim` plugin is bundled into cdin itself, so it is always there; the
manager sees that and never tries to install it twice.

## What to notice

**It's an integration, and that changes what it may do.** A `X/core/` plugin
may not depend on another X plugin at all. An integration may, and has to
declare what it depends on:

```lua
dependencies = { "vim" }
```

The manager sorts on that declaration, so vim is loaded first, and `make
validate` checks every cross-plugin `require` against it.

**It reaches vim through one module.** `X.core.vim.registry`, which offers
seven seams — ex-commands, three kinds of key, <kbd>Ctrl</kbd>+<kbd>W</kbd>
characters, named actions, and one event. This claims two. The full table,
with a worked example, is in
[docs/extending-vim.md](../../docs/extending-vim.md).

**It doesn't reuse `02-word-count`.** It could, and the counting is the same
nineteen lines either way. Depending on the other plugin would make the two a
unit you have to install and remove together, and an integration that drags in
a capability it doesn't need is how a catalog stops being something you can
reason about.

**The key is `gc`, chosen after looking.** Every key in vim mode is a
negotiation with vim core and with every other integration. This catalog is
small enough to read; that's the cheapest way to avoid being the reason two
plugins stop working.

## Files

| file | holds |
| --- | --- |
| `init.lua` | the manifest and the load guard |
| `commands.lua` | `:wordcount` / `:wc` |
| `keymap.lua` | <kbd>g</kbd><kbd>c</kbd> |

Back to [the examples index](../README.md).
