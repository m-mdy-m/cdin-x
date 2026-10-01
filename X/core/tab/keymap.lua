local keymap = require "core.input.keymap"

local M = {}

local MAP = {
  ["ctrl+tab"]       = "tab:next",
  ["ctrl+shift+tab"] = "tab:prev",
  ["ctrl+1"] = "tab:go-1",
  ["ctrl+2"] = "tab:go-2",
  ["ctrl+3"] = "tab:go-3",
  ["ctrl+4"] = "tab:go-4",
  ["ctrl+5"] = "tab:go-5",
  ["ctrl+6"] = "tab:go-6",
  ["ctrl+7"] = "tab:go-7",
  ["ctrl+8"] = "tab:go-8",
  ["ctrl+9"] = "tab:go-9",
  ["ctrl+t"] = "tab:new",
  ["ctrl+shift+w"] = "tab:close",
  ["ctrl+shift+pageup"] = "tab:move-left",
  ["ctrl+shift+pagedown"] = "tab:move-right",
}

function M.register()
  keymap.add(MAP)
end

function M.unregister()
  keymap.remove(MAP)
end

return M
