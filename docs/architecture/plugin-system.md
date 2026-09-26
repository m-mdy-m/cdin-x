# CDIN ↔ CDIN-X Plugin System

This document defines the runtime contract between the `cdin` editor repository and
the `cdin-x` extension repository.

## 1. Repository boundary

`cdin` owns the editor runtime:

```text
src/                      C host and native APIs
data/core/                Lua editor core
  documents, views,
  commands, keymaps,
  syntax, project, git...
data/core/x/              CDIN-X runtime integration
data/X/core/              mandatory built-in extensions
data/fonts/               core assets
```

`cdin-x` owns the ecosystem:

```text
core/                     runtime sources copied into data/core/x/
X/                        official extension sources and catalog
registry/                 generated metadata
scripts/                  development helpers
templates/                extension scaffolds
docs/                     extension contracts
```

There is no Go runtime and there is no microservice boundary. Lua extensions execute
inside the CDIN process. A plugin may launch a separate process when it integrates an
external program such as an LSP server, debugger, formatter, compiler, or Git tool.

## 2. Three extension sources

At runtime the manager sees three sources with strict precedence:

```text
1. builtin       EXEDIR/data/X
2. installed     user data/extensions
3. registry      cached cdin-x/X
```

A registry extension is **not** runtime code yet. It becomes executable only after it
is copied into the user's installed-extension store.

This is the key distinction:

```text
cdin-x repository  -> source/catalog
user extension dir -> executable installed copy
CDIN data/X/core   -> immutable built-in copy
```

## 3. Boot sequence

```text
C host
  │
  └─ data/core/init.lua
       │
       ├─ core runtime
       ├─ project state
       ├─ commands/views/events
       │
       └─ core.load_plugins()
             │
             └─ require("core.x")
                    │
                    ├─ load state
                    ├─ scan built-ins
                    ├─ scan installed extensions
                    ├─ resolve dependencies
                    ├─ load enabled extensions
                    └─ register CDIN-X UI commands
       │
       └─ load external user config
```

The boot path never requires the network. If there is no registry cache and Git is not
available, CDIN can still start with all built-ins.

## 4. Built-in extensions

The current mandatory set is:

```text
core
autocomplete
autoreload
autoupdate
projectsearch
session
trimwhitespace
vim
treeview
tab
window
```

They all use the same plugin contract as optional extensions, but their manifest has
`essential = true` and they are shipped under `data/X/core/`.

The manager therefore treats them as:

```text
install     already present
enable      always enabled
disable     forbidden
uninstall   forbidden
```

## 5. Plugin contract

Every extension directory has:

```text
init.lua
manifest.lua
README.md
```

`init.lua` returns a module:

```lua
local M = {}

function M.init(core, config)
  -- register commands, hooks, keymaps, views, etc.
end

function M.unload()
  -- undo runtime registrations when possible
end

return M
```

The manifest is metadata:

```lua
return {
  name = "git-tools",
  version = "0.1.0",
  description = "Git integration for CDIN",
  category = "git",
  type = "plugin",
  essential = false,
  dependencies = {},
  min_cdin_version = "0.5.0",
}
```

`README.md` is human-facing documentation and is shown through the extension manager.

## 6. Loading and dependencies

When CDIN starts, the manager collects built-ins plus installed, non-disabled
extensions. Dependencies are resolved topologically before `init.lua` is loaded.
Cycles are rejected.

For example:

```text
lsp-ui
  └─ popup
       └─ async
```

If `lsp-ui` is installed, the manager installs missing dependencies first and loads
`async -> popup -> lsp-ui`.

A dependency can never force removal of another installed extension: uninstall/disable
is blocked while another installed extension still depends on it.

## 7. Installation locations

The user never has to edit the CDIN installation directory to add an optional extension.

```text
Linux/macOS
~/.config/cdin/user/init.lua
~/.local/share/cdin/extensions/<category>/<name>/
~/.local/share/cdin/registry/cdin-x/
~/.local/share/cdin/extensions.lua

Windows
%APPDATA%/cdin/user/init.lua
%LOCALAPPDATA%/cdin/extensions/<category>/<name>/
%LOCALAPPDATA%/cdin/registry/cdin-x/
%LOCALAPPDATA%/cdin/extensions.lua
```

Exact roots can be overridden by the platform's standard `XDG_*` variables on Unix.

## 8. The `m` menu

The Vim `m` key is not owned by the package manager. Vim remains the editor's global
menu gateway.

Its flow is:

```text
m
 │
 └─ Extensions
      │
      ├─ browse catalog
      ├─ search
      ├─ view README
      ├─ install
      ├─ enable / disable
      ├─ uninstall
      ├─ install local
      └─ refresh catalog
```

This separation is deliberate:

```text
Vim/fmenu       = UI gateway
core.x.command  = extension UI
core.x.manager  = extension state + lifecycle
core.x.manifest = metadata contract
```

Changing the UI later therefore does not change the extension lifecycle engine.

## 9. Local development

A developer can build an extension without registering it:

```text
my-plugin/
├── init.lua
├── manifest.lua
└── README.md
```

Use **Install Local** from the CDIN-X menu. The manager copies it into the user's
extension store. No PR and no central registry is required.

To publish it, add the extension under `X/<category>/<name>/`, regenerate
`X/manifest.lua`, run the lightweight validation, and open a PR.

## 10. Why categories are open-ended

The runtime does not hard-code a category list. It scans the immediate subdirectories
of `X/` and reads the category from each manifest.

Therefore future categories such as these require no CDIN runtime change:

```text
X/tools/
X/ai/
X/compiler/
X/database/
X/embedded/
X/network/
```

## 11. Themes

Themes use the same registry/install mechanism but have `type = "theme"` and provide:

```text
theme.lua
```

That's it. A theme is just a single Lua file returning a style table. No manifest, no init, no README needed. This keeps themes minimal — often just 30 lines.

The default theme is provided as `cdin-x/X/themes/default/theme.lua`
and installed into the editor's font/assets directory. Optional CDIN-X
themes are in the catalog and applied by `core.themes` without executing
any extension code.
