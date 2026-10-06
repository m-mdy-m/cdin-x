-- The generic menu capability: a searchable, composable menu that other
-- packages extend.
--
-- This is the *only* menu engine in the repository. Features contribute
-- sections to it rather than each building their own — vim mode, the extension
-- manager and the vim integrations all render through here. It knows nothing
-- about any of them; a feature provides a function returning sections and this
-- module orders and renders them.
--
--   menu.define(name, spec)                  create a menu
--   menu.extend(name, id, fn, order)         add a section provider
--   menu.remove_extension(name, id)          drop one again
--   menu.set_context_provider(...)           choose what the menu acts on
--   menu.remove_context_provider(name, id)
--   menu.open(name, override_context)        show it
local M = {}

M.config = {}

local loaded = false

function M.init(core, config)
  if loaded then return end
  loaded = true
  core.menu = require "menu.impl"
  core.log("Menu extension loaded")
end

function M.unload()
  if not loaded then return end
  require("core").menu = nil
  loaded = false
end

return M