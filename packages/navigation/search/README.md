# search

Document search and replace, and project-wide search.

```text
search/
├── manager/    shared state, document helpers, highlight state
├── buffer.lua  document search, find, replace
├── project.lua project-wide results view
├── commands.lua
├── keymap.lua
└── init.lua    the manifest, and assembly
```

`buffer.lua` and `project.lua` register nothing. Commands and bindings live in
their own files on purpose, so an integration can use the search API without
also inheriting search's keys.

The manifest is inline in `init.lua` — there is no `manifest.lua` in this
plugin, and there is no such file in the catalog.

**Full page:** [search — what it does, what you press, and how it works](../../../docs/plugins/search.md)
