# cdin-x

**cdin-x** is the extension ecosystem for [cdin](https://github.com/m-mdy-m/cdin).
It is deliberately separate from the editor runtime: CDIN ships only its core runtime
and a small set of mandatory built-in extensions, while optional extensions live here
and are installed per-user.

## Architecture

```text
cdin
├── data/core/                 CDIN runtime
├── data/core/x/               cdin-x manager + loader + manifest API
├── data/X/core/               mandatory built-in extensions
└── data/fonts/                core assets

cdin-x
├── core/                      extension runtime installed into CDIN
├── X/                         official extension catalog
│   ├── core/                  built-in extension sources
│   ├── languages/             optional language support
│   ├── lsp/                   optional LSP support
│   ├── formatters/             optional formatters
│   ├── git/                   optional Git integrations
│   ├── debug/                 optional debugger integrations
│   ├── ui/                    optional UI extensions
│   ├── utils/                 optional utility extensions
│   └── themes/                optional themes (theme.lua only)
├── fonts/                     bundled fonts (font.ttf, monospace.ttf, icons.ttf)
├── templates/                 plugin scaffolds
├── registry/                  generated catalog metadata
├── scripts/                   development helpers
└── docs/                      architecture/API/developer docs
```

CDIN-X is **not** a microservice system. Extensions are Lua modules loaded in the
CDIN process. External tools such as language servers or debuggers may run as child
processes when an extension needs them.

## Extension lifecycle

```text
registry → install → local store → enable → load
                         ↓
                     disable
                         ↓
                    uninstall
```

The runtime never executes extension source directly from the registry clone. Official
extensions are copied into the user's extension store before they are loaded.

### Storage

Configuration follows platform conventions:

- Linux/macOS: `${XDG_CONFIG_HOME:-~/.config}/cdin` and `${XDG_DATA_HOME:-~/.local/share}/cdin`
- Windows: `%APPDATA%/cdin` and `%LOCALAPPDATA%/cdin`

The important locations are:

```text
<config>/cdin/user/init.lua         personal configuration
<data>/cdin/extensions/             installed extensions
<data>/cdin/extensions.lua          enable/disable state
<data>/cdin/registry/cdin-x/        cached catalog
```

## Built-in vs optional

The built-in extensions are always present and cannot be disabled or removed:

- `core`
- `autocomplete`
- `autoreload`
- `autoupdate`
- `projectsearch`
- `session`
- `trimwhitespace`
- `vim`
- `treeview`
- `tab`
- `window`

Everything else is optional unless a future CDIN distribution explicitly promotes an
extension into the built-in bundle.

## Creating an extension

A minimal extension is only three files:

```text
X/utils/my-extension/
├── init.lua
├── manifest.lua
└── README.md
```

`init.lua`:

```lua
local M = {}

function M.init(core, config)
  core.log("my-extension loaded")
end

function M.unload()
end

return M
```

`manifest.lua`:

```lua
return {
  name = "my-extension",
  version = "0.1.0",
  description = "My CDIN extension",
  category = "utils",
  type = "plugin",
  essential = false,
  dependencies = {},
  min_cdin_version = "0.5.0",
}
```

Developers can install a local extension directly from the CDIN-X manager, then open
a pull request to register it in this repository.

## UI

The existing Vim `m` menu remains the gateway. Its **Extensions** item opens the
CDIN-X manager, where users can browse the catalog, read each extension's README,
install, enable, disable, and uninstall optional extensions.

## Contributing

Keep the runtime small. New functionality belongs in an extension whenever it does
not need to be part of the editor core. Registry validation focuses on manifests,
structure, dependencies, and CDIN compatibility; CDIN-X intentionally avoids a large
test suite for every plugin.
