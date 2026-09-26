# Development Guide

## Getting Started

```bash
make setup
make new-plugin my-awesome-plugin languages
make validate
make registry
make plugin-list
```

The project intentionally keeps the quality gate small: structure, manifest shape,
Lua syntax/formatting, and registry generation. Every extension does not need a large
test suite.

## Creating an Extension

```text
X/<category>/<plugin-name>/
├── init.lua
├── manifest.lua
└── README.md
```

`init.lua`:

```lua
local M = {}

function M.init(core, config)
  core.log("plugin loaded")
end

function M.unload()
end

return M
```

`manifest.lua`:

```lua
return {
  name = "my-plugin",
  version = "0.1.0",
  description = "Does something useful",
  category = "utils",
  type = "plugin",
  essential = false,
  dependencies = {},
  min_cdin_version = "0.5.0",
}
```

The scaffold command creates these files automatically:

```bash
lua scripts/new-plugin.lua my-plugin utils
```

## Local development

Install the extension directly from the CDIN-X manager with **Install Local**. This
lets a contributor iterate without adding anything to the registry.

For extensions that are eventually published, keep all implementation files inside
the extension directory so the package remains self-contained.

## Submitting to the registry

1. Create `X/<category>/<plugin-name>/`.
2. Add `init.lua`, `manifest.lua`, and `README.md`.
3. Run `make validate` and `make registry`.
4. Open a pull request to `cdin-x`.
5. Maintainers review the metadata, dependencies, runtime behavior, and README.

## Conventional Commits

- `feat(scope): description`
- `fix(scope): description`
- `docs(scope): description`
