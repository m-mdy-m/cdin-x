local M = {
  name = "theme_switcher",
  version = "0.2.0",
  description = "Switch between installed CDIN themes",
  author = "cdin Team",
  license = "MIT",
  category = "optional",
  type = "plugin",
  essential = false,
  dependencies = {},
  min_cdin_version = "0.5.0",
  tags = { "theme", "ui" },
}
M.config = {}

local loaded = false

function M.init()
  if loaded then return end
  loaded = true
  require("X.optional.theme_switcher.impl").register()
end

function M.unload()
  if not loaded then return end
  require("X.optional.theme_switcher.impl").unregister()
  loaded = false
end

return M
