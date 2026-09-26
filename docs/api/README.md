# cdin-x API

## Extension contract

```lua
local M = {}

function M.init(core, config)
end

function M.unload()
end

return M
```

An extension directory must contain:

```text
init.lua
manifest.lua
README.md
```

## Manifest

```lua
return {
  name = "my-extension",
  version = "0.1.0",
  description = "...",
  category = "utils",
  type = "plugin", -- or "theme"
  essential = false,
  dependencies = {},
  min_cdin_version = "0.5.0",
}
```

## Manager API

`require "core.x.manager"` exposes:

- `bootstrap()`
- `list()` / `search()` / `get()`
- `install(name)` / `install_local(path)`
- `enable(name)` / `disable(name)`
- `uninstall(name)`
- `refresh_registry()`
- `open_readme(name)`

The manager is independent of any specific extension implementation.
