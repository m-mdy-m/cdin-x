-- Manifest fields (name, version, description, ...) live inline below --
-- this used to be a separate manifest.lua that init.lua dofile'd; now
-- it's just the top of the returned table, same as any single-file
-- plugin. Everything else in this directory (the sibling .lua modules
-- this file requires) is unchanged.
local M = {
  name = "tab",
  version = "0.1.0",
  description = "Tab management and tab session support",
  author = "cdin Team",
  license = "MIT",
  category = "core",
  type = "plugin",
  essential = true,
  dependencies = {  },
  min_cdin_version = "0.5.0",
  tags = { "essential", "ui", "tabs" },
}
M.config = {}

local loaded = false
function M.init(core, config)
  if loaded then return end
  loaded = true
  require "X.core.tab.impl"
  core.log("Tab extension loaded")
end
function M.unload() end
return M
