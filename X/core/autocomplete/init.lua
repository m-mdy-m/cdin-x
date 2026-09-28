-- Autocomplete: a suggestion popup fed by providers.
--
-- The default provider offers symbols from every open document. Anything
-- else — language keywords, snippet names, project tags — is added as
-- another provider:
--
--   require("X.core.autocomplete.api").add {
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
-- The manifest is inline (there is no manifest.lua) and api.lua is
-- required inside init(), so the extension catalog can dofile() this file
-- to read the manifest without patching RootView for a plugin that may
-- never be loaded.
local M = {
  name = "autocomplete",
  version = "0.2.0",
  description = "Symbol-based completion popup for open documents, extensible with providers",
  author = "cdin Team",
  license = "MIT",
  category = "core",
  type = "plugin",
  essential = false,
  dependencies = {},
  min_cdin_version = "0.5.0",
  tags = { "completion", "editor" },
}
M.config = {}

local loaded = false

function M.init()
  if loaded then return end
  loaded = true

  local api = require "X.core.autocomplete.api"
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
  require("X.core.autocomplete.api").unregister()
  loaded = false
end

return M
