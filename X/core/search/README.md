# Search

The `search` core plugin owns document search/replace and project-wide search.

## Structure

```text
search/
├── manager/
│   └── init.lua   # shared state, document helpers, highlight state
├── buffer.lua     # document search / find / replace behavior
├── project.lua    # project-wide search results view and search behavior
├── commands.lua   # command registration only
├── keymap.lua     # default keymap registration only
├── init.lua        # plugin lifecycle / assembly
└── manifest.lua    # plugin metadata
```

`buffer.lua` and `project.lua` intentionally do not register commands or keymaps.
Shared state and helpers belong to `manager/`; command and keymap wiring are kept
separate so integrations can depend on the search API without pulling in bindings.
