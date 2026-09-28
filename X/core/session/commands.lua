-- Session commands. Renamed from command.lua so it matches the commands.lua
-- convention every other plugin uses.
--
-- Reached through the session api rather than core.session, so the commands
-- work even if something has swapped that global.
local command = require "core.input.command"
local core    = require "core"
local session = require "X.core.session.api"

local M = {}

local MAP = {
  ["session:open-recent"] = function()
    session.open_recent_files_picker()
  end,
  ["session:open-recent-dirs"] = function()
    session.open_recent_dirs_picker()
  end,
  ["session:save"] = function()
    if session.save() then
      local files, dirs = session.info()
      core.log("session: saved (%d files, %d dirs)", files, dirs)
    end
  end,
  ["session:clear"] = function()
    session.clear()
    core.log("session: cleared")
  end,
  ["session:show-info"] = function()
    local files, dirs, path = session.info()
    core.log("session: %d files, %d dirs — %s", files, dirs, path)
  end,
}

local NAMES = {
  "session:open-recent", "session:open-recent-dirs", "session:save",
  "session:clear", "session:show-info",
}

function M.register()
  command.add(nil, MAP, true)
end

function M.unregister()
  command.remove(NAMES)
end

return M
