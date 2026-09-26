# cdin-x Examples

This directory contains example plugins demonstrating how to create plugins for cdin-x.

## Example Plugins

### 🌍 terraform/ — Full Language Plugin

A complete language plugin showing:
- LSP client integration
- `terraform fmt` formatting command
- `terraform validate` linting command
- Keymap bindings
- Background coroutines
- Configuration options

**Best for learning full plugin development.**

### 📄 lua/ — Minimal Plugin

The simplest possible plugin showing:
- Basic structure (init.lua, manifest.lua, README.md)
- Simple commands
- Configuration toggles

**Best for getting started quickly.**

## Common Patterns

### Adding a New Command

```lua
local command = require "core.input.command"
command.add(nil, {
  ["myplugin:do-thing"] = function()
    core.log("Doing a thing!")
  end,
})
```

### Adding a Keymap

```lua
local keymap = require "core.input.keymap"
keymap.add({
  ["ctrl+shift+f"] = "myplugin:format",
})
```

### Using Background Threads

```lua
core.add_thread(function()
  while true do
    -- Background work
    coroutine.yield(1)
  end
end)
```

### Reading Plugin Config

```lua
function M.init(core, config)
  if config.my_plugin_enabled then
    -- Do something
  end
end
```

## File Structure

Every example follows this pattern:

```
examples/<category>/<plugin-name>/
├── <plugin-name>.lua   ← Main plugin code
├── manifest.lua        ← Plugin metadata
└── README.md           ← Documentation
```

## Contributing Examples

To add a new example:
1. Create `examples/<category>/<plugin-name>/`
2. Add the 3 required files
3. Open a PR

## Need Help?

See [Development Guide](development/README.md) for the full plugin creation guide.
