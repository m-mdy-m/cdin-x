-- Tab session: persist the open tabs and restore them next run.
--
-- This is an integration rather than part of the tab plugin because it
-- needs two capabilities — tabs and the session plugin's quit hook — and
-- neither should know about the other. It is the only current user of
-- session.on_quit(), which is why that seam exists.
--
-- The manifest is inline (there is no manifest.lua) and session.lua is
-- required inside init(), so the extension catalog can dofile() this file
-- to read the manifest without subscribing a quit hook for a plugin that
-- may never be installed.
local M = {
  name = "tab-session",
  version = "0.2.0",
  description = "Persist open tabs and restore them on the next run",
  author = "cdin Team",
  license = "MIT",
  category = "integration",
  type = "plugin",
  essential = false,
  dependencies = { "tab", "session" },
  min_cdin_version = "0.5.0",
  tags = { "tab", "session", "integration" },
}

local loaded = false

function M.init()
  if loaded then return end
  loaded = true
  require("X.integration.tab-session.session").register()
end

function M.unload()
  if not loaded then return end
  require("X.integration.tab-session.session").unregister()
  loaded = false
end

return M
