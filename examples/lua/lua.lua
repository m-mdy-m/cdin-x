-- examples/lua/lua.lua
-- Example: Lua Language Plugin
-- A minimal language plugin showing the simplest possible structure.
--
-- This is the simplest example — just a syntax support plugin.
-- More complex plugins (like terraform above) add LSP, formatters, etc.

local M = {}

-- ═══════════════════════════════════════════════
-- REQUIRED: Plugin metadata
-- ═══════════════════════════════════════════════

M.name = "lua_lang"
M.version = "0.1.0"
M.description = "Lua language syntax support and tools"
M.author = "cdin Team"
M.license = "MIT"
M.dependencies = {}

M.config = {
  lua_auto_format = true,
  lua_lsp_enabled = true,
}

M.essential = false
M.min_cdin_version = "0.5.0"
M.tags = {"language", "lua", "syntax"}
M.category = "languages"

-- ═══════════════════════════════════════════════
-- MANDATORY: init()
-- ═══════════════════════════════════════════════

function M.init(core, config)
  local command = require "core.input.command"

  -- Register a simple format command
  command.add(nil, {
    ["lua:format"] = function()
      core.log("Lua: formatting...")
    end,
    ["lua:toggle-lsp"] = function()
      config.lua_lsp_enabled = not config.lua_lsp_enabled
      core.log("Lua LSP: %s", config.lua_lsp_enabled and "enabled" or "disabled")
    end,
  })

  core.log("✓ Lua language plugin loaded")
end

-- ═══════════════════════════════════════════════
-- MANDATORY: unload()
-- ═══════════════════════════════════════════════

function M.unload()
  core.log("Lua plugin unloaded")
end

return M
