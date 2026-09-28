-- Session ↔ theme switcher.
--
-- The theme switcher applies a theme; the session plugin persists the
-- choice. Neither knows the other exists — the switcher used to reach into
-- the session plugin's private core.session.set_theme() while its manifest
-- claimed no dependencies at all. This integration is the only place the
-- two are named together.
--
-- There are no commands and no keys here, only a subscription: the switcher
-- publishes on_change, and this connects it to the session's set_theme.
--
-- The manifest is inline, and nothing is required at the top of the file,
-- so the extension catalog can dofile() this to read the manifest without
-- loading either plugin for a plugin that may never be installed.
local M = {
  name = "session-theme-switcher",
  version = "0.1.0",
  description = "Persist the theme chosen with the theme switcher into the session",
  author = "cdin Team",
  license = "MIT",
  category = "integration",
  type = "plugin",
  essential = false,
  dependencies = { "session", "theme_switcher" },
  min_cdin_version = "0.5.0",
  tags = { "session", "theme", "integration" },
}

local function on_theme_change(name)
  require("X.core.session.api").set_theme(name)
end

local loaded = false

function M.init()
  if loaded then return end
  loaded = true
  require("X.optional.theme_switcher.impl").on_change(on_theme_change)
end

function M.unload()
  if not loaded then return end
  require("X.optional.theme_switcher.impl").off_change(on_theme_change)
  loaded = false
end

return M
