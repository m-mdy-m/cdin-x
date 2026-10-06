-- Autocomplete: a suggestion popup fed by providers.
--
-- The default provider offers symbols from every open document. Anything
-- else — language keywords, snippet names, project tags — is added as
-- another provider:
--
--   require("complete.api").add {
--     name  = "lua-keywords",
--     files = "%.lua$",
--     items = { "function", "end", "local" },
--   }
--
--   api.on_change(function() ... end)   -- not built in; call api.set on edit
--
-- Layout:
--   api.lua      the provider registry and the load point
--   source.lua   the built-in provider: open-document symbols
--   suggest.lua  fuzzy matching, dedup, and the current suggestion list
--   popup.lua    geometry and drawing
--   commands.lua accept / previous / next / cancel
--   keymap.lua   Tab, Up, Down, Escape
--
-- The manifest is package.lua, which the catalog reads without running anything
-- here, so the requires below may sit at the top whenever the order suits. They
-- are inside init() because they are not cheap: pulling in api.lua patches
-- RootView.
local M = {}

M.config = {}

local loaded = false

function M.init()
  if loaded then return end
  loaded = true

  local api = require "complete.api"
  api.register()

  -- Published on core so a user config or another plugin can reach the
  -- provider registry without knowing the module path, the same way
  -- search publishes core.search and menu publishes core.menu.
  require("core").autocomplete = api
end

function M.unload()
  if not loaded then return end
  local core = require "core"
  core.autocomplete = nil
  require("complete.api").unregister()
  loaded = false
end

return M
