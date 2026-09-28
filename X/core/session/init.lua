-- Persistent session state: recent files, recent directories, the last
-- directory and the chosen theme, restored on the next run.
--
-- The manifest is inline (there is no manifest.lua) and api.lua is
-- required inside init(), so the extension catalog can dofile() this file
-- to read the manifest without installing hooks or wrapping core.quit for
-- a plugin that may never be loaded.
local M = {
  name = "session",
  version = "0.2.0",
  description = "Persistent session restore for buffers and project state",
  author = "cdin Team",
  license = "MIT",
  category = "core",
  type = "plugin",
  essential = false,
  dependencies = {},
  min_cdin_version = "0.5.0",
  tags = { "session", "state" },
}

local loaded = false

function M.init(core, config)
  if loaded then return end
  loaded = true
  require("X.core.session.api").register()
  core.log("Session extension loaded")
end

function M.unload()
  if not loaded then return end
  require("X.core.session.api").unregister()
  loaded = false
end

return M
