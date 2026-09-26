-- examples/lua/manifest.lua
return {
  name = "lua_lang",
  version = "0.1.0",
  description = "Lua language syntax support and tools",
  author = "cdin Team",
  license = "MIT",
  path = "examples/lua",
  tags = {"language", "lua", "syntax"},
  dependencies = {},
  config = {
    lua_auto_format = true,
    lua_lsp_enabled = true,
  },
  essential = false,
  min_cdin_version = "0.5.0",
  category = "languages",
}
