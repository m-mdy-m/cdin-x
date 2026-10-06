-- File tree sidebar with navigation and filesystem actions.
--
--   treeview_impl.lua  the view: drawing, cursor, expansion
--   commands.lua       the eighteen treeview commands
--   keymap.lua         its key bindings
--   api.lua            the provider registry integrations extend
--   cache.lua          tree item cache
--   readonly.lua       read-only file cache (badges)
--
-- The treeview knows nothing about git or any other capability: it exposes a
-- generic badge/refresh provider registry (api.lua) that integrations fill in —
-- see the git package's `with/treeview.lua` seam.
--
-- The manifest is package.lua, which the catalog reads without running anything
-- here, so the requires below may sit at the top whenever the order suits.
local M = {}

M.config = {}

local loaded = false

function M.init(core, config)
  if loaded then return end
  loaded = true

  local view = require "treeview.treeview_impl"
  core.treeview = view

  require("treeview.commands").register(view)
  require("treeview.keymap").register()

  core.log("Treeview extension loaded")
end

function M.unload()
  if not loaded then return end
  require("treeview.keymap").unregister()
  require("treeview.commands").unregister()
  require("core").treeview = nil
  loaded = false
end

return M