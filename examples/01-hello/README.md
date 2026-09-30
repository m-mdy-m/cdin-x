# hello

The smallest plugin that does something: one command, one key binding, and an
`unload()` that takes both back out.

## Try it

```sh
cd <site>            # <data_home>/cdin/site
cp -r /path/to/examples/01-hello hello
```

Then in cdin: <kbd>Shift</kbd>+<kbd>M</kbd> → **Install Local** → point it at
`<site>/hello`.

Or copy the directory anywhere and install from there — the site directory is
just where the manager copies it to.

<kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>H</kbd> says hello. It also shows up in the
command palette as `hello:say`, which is the point of binding a name rather
than a function.

## What to notice

**The manifest is the returned table.** There is no separate `manifest.lua`.

**Nothing is required above `init()`.** `commands.lua` and `keymap.lua` are
required inside it, and that's not a style choice — the catalog `dofile()`s
this file to read the manifest, and a top-level require would run the whole
subtree just to look up a name.

**`loaded` is there.** A plugin `dofile`d once and `require`d once is two
module instances, each with its own `loaded`, and both would do the work.

**`unload()` undoes all three things** — key, command, help entries. Leaving
one behind is how a reload ends up with two of everything.

## Files

| file | holds |
| --- | --- |
| `init.lua` | the manifest, the load guard, `init` / `unload` |
| `commands.lua` | `hello:say` |
| `keymap.lua` | <kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>H</kbd> |

Next: [02-word-count](../02-word-count) reads a document and draws a status
pill.
