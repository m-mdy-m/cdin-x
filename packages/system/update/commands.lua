-- Update-check commands. Registered and unregistered as a unit.
local command = require "core.input.command"
local Impl    = require "update.impl"

local M = {}

local MAP = {
  ["autoupdate:check"] = function() Impl.check() end,
  ["autoupdate:skip-version"] = function() Impl.dismiss() end,
}

local NAMES = { "autoupdate:check", "autoupdate:skip-version" }

function M.register()
  command.add(nil, MAP, true)
end

function M.unregister()
  command.remove(NAMES)
end

return M
