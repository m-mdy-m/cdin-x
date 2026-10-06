-- Check CDIN releases and offer updates.
--
-- The manifest is package.lua, which the catalog reads without running anything
-- here. The siblings are required inside init() rather than at the top because
-- they are not cheap: starting a network thread for a package that may never be
-- loaded is exactly what the catalog avoids.
local M = {}

local loaded = false

function M.init()
  if loaded then return end
  loaded = true
  require("update.commands").register()
  require("update.keymap").register()
end

function M.unload()
  if not loaded then return end
  require("update.keymap").unregister()
  require("update.commands").unregister()
  require("update.impl").remove_badge()
  loaded = false
end

return M