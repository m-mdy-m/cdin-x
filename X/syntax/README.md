# syntax

Language definitions — one file per language, named for the language.

```text
c.lua  javascript.lua  lua.lua  markdown.lua  python.lua  typescript.lua
```

A definition is a table of patterns the host's highlighter walks. It has no
commands, no keys, and no dependency beyond the host, which is why the
directory is its own category rather than a `core/` plugin: there is nothing
here to load and nothing to unload.

Adding one is a matter of dropping in a file and adding a line to
[`X/manifest.lua`](../manifest.lua) — or running `make manifest`, which is
usually the better answer.

**Full page:** [a-syntax-definition — what it does, what you press, and how it works](../../docs/building/a-syntax-definition.md)
