-- Key binding for the update check.
local keymap = require "core.input.keymap"

local M = {}

local MAP = { ["ctrl+shift+u"] = "autoupdate:check" }

function M.register()
  keymap.add(MAP, true)
end

function M.unregister()
  keymap.remove(MAP)
end

return M
