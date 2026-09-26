# lua_lang

Lua language support for cdin.

## Description

Minimal Lua syntax support plugin. Shows the simplest plugin structure.

## Installation

Install from cdin using the Plugin Manager (`m` key).

Or manually copy to `X/languages/lua_lang/`.

## Usage

| Command | Description |
|---------|-------------|
| `lua:format` | Format the current Lua document |
| `lua:toggle-lsp` | Toggle LSP client on/off |

## Configuration

```lua
-- data/user/init.lua
config.lua_auto_format = true
config.lua_lsp_enabled = true
```

## Contributing

To submit this plugin to the cdin-x registry, create a PR.

## License

MIT
