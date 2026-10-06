-- The workspace package: tabs, windows and sessions.
--
-- Nothing here that all four features need. Each is a feature so a user can close
-- windows without losing their session, or keep tabs and drop session restore --
-- and each is a directory of modules under this package, required by name.
local M = {}

function M.init()
  if M.loaded then return end
  M.loaded = true
end

function M.unload()
  M.loaded = false
end

return M