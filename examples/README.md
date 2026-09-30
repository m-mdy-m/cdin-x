# Examples

Three plugins, smallest first. Each is a complete, installable directory —
copy it somewhere, point **Install Local** at it, and it runs.

They live here rather than in `X/` on purpose. `X/` is the catalog, and
everything in it is something this project offers everybody; an example is a
starting point for *your* plugin, and it should not end up in your catalog
because you read it.

| example | shows | lines |
| --- | --- | --- |
| [01-hello](01-hello) | the minimum: a command, a key, and an `unload()` that takes both back | ~120 |
| [02-word-count](02-word-count) | reading a document, and the status-bar pill registry | ~170 |
| [03-vim-word-count](03-vim-word-count) | extending vim mode through its registry | ~140 |

Read them in order. Each one introduces exactly one new idea and nothing else.

## Running one

```sh
cd <site>                      # <data_home>/cdin/site
cp -r /path/to/examples/01-hello hello
```

In cdin: <kbd>Shift</kbd>+<kbd>M</kbd> → **Install Local** → the directory you
just copied. No build, no restart.

The copy step is only because **Install Local** copies, the same as it does
for a plugin from the catalog. For iterating on your own plugin you can skip
it: keep the directory where it is and re-run **Install Local** after each
change.

## Before you adapt one

Two things are worth knowing that the examples show but don't labour:

**A plugin's top-level file is a manifest and nothing else.** The catalog
`dofile()`s it to read the name and dependencies, so a `require` above
`init()` runs your whole subtree just to be looked up. Every example puts its
requires inside `init()` for this reason, not for tidiness.

**`unload()` has to undo all of `init()`.** Key bindings, commands, help
entries, status pills. It is the part everyone skips and the only part that
makes disable actually mean something.

Both are explained properly in
[writing-a-plugin.md](../docs/writing-a-plugin.md).
