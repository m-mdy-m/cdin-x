-- Check CDIN releases and offer updates.
--
-- The manifest is inline (there is no manifest.lua) and the siblings are
-- required inside init(), so the extension catalog can dofile() this file
-- to read the manifest without starting a network thread for a plugin that
-- may never be loaded.
local M = {
  name = "autoupdate",
  version = "0.2.0",
  description = "Check CDIN releases and offer updates",
  author = "cdin Team",
  license = "MIT",
  category = "core",
  type = "plugin",
  essential = false,
  dependencies = {},
  min_cdin_version = "0.5.0",
  tags = { "update" },
}

local loaded = false

function M.init()
  if loaded then return end
  loaded = true
  require("X.core.autoupdate.commands").register()
  require("X.core.autoupdate.keymap").register()
end

function M.unload()
  if not loaded then return end
  require("X.core.autoupdate.keymap").unregister()
  require("X.core.autoupdate.commands").unregister()
  require("X.core.autoupdate.impl").remove_badge()
  loaded = false
end

return M
