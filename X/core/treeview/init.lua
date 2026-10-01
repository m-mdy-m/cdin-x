-- File tree sidebar with navigation and filesystem actions.
--
--   treeview_impl.lua  the view: drawing, cursor, expansion
--   commands.lua       the eighteen treeview commands
--   keymap.lua         its key bindings
--   api.lua            the provider registry integrations extend
--   cache.lua          tree item cache
--   readonly.lua       read-only file cache (badges)
--
-- The treeview knows nothing about git or any other capability: it exposes
-- a generic badge/refresh provider registry (api.lua) that integrations
-- fill in — see X/integration/git-treeview.
--
-- The manifest is inline (there is no manifest.lua) and everything is
-- required inside init(), so the extension catalog can dofile() this file
-- to read the manifest without splitting a pane into the user's layout.
local M = {
  name = "treeview",
  version = "0.2.0",
  description = "File tree sidebar with navigation and filesystem actions",
  author = "cdin Team",
  license = "MIT",
  category = "core",
  type = "plugin",
  essential = false,
  dependencies = {},
  min_cdin_version = "0.5.0",
  tags = { "essential", "ui", "navigation", "filesystem" },
}
M.config = {}

local loaded = false

function M.init(core, config)
  if loaded then return end
  loaded = true

  local view = require "X.core.treeview.treeview_impl"
  core.treeview = view

  require("X.core.treeview.commands").register(view)
  require("X.core.treeview.keymap").register()

  core.log("Treeview extension loaded")
end

function M.unload()
  if not loaded then return end
  require("X.core.treeview.keymap").unregister()
  require("X.core.treeview.commands").unregister()
  -- The pane goes back with the plugin. A treeview that is disabled but still
  -- owns a column is an empty strip of screen with no key that closes it.
  require("X.core.treeview.treeview_impl").detach()
  require("core").treeview = nil
  loaded = false
end

return M
