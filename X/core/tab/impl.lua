local core   = require "core"
local style  = require "core.style"
local keymap = require "core.input.keymap"
local M      = require "X.core.tab.manager"

require "X.core.tab.commands"

keymap.add({
  -- cycle
  ["ctrl+tab"]       = "tab:next",
  ["ctrl+shift+tab"] = "tab:prev",

  -- jump to tab N  (Ctrl+1 … Ctrl+9, VSCode-style)
  ["ctrl+1"] = "tab:go-1",
  ["ctrl+2"] = "tab:go-2",
  ["ctrl+3"] = "tab:go-3",
  ["ctrl+4"] = "tab:go-4",
  ["ctrl+5"] = "tab:go-5",
  ["ctrl+6"] = "tab:go-6",
  ["ctrl+7"] = "tab:go-7",
  ["ctrl+8"] = "tab:go-8",
  ["ctrl+9"] = "tab:go-9",

  -- lifecycle
  ["ctrl+t"]       = "tab:new",
  ["ctrl+shift+w"] = "tab:close",

  -- reorder
  ["ctrl+shift+pageup"]   = "tab:move-left",
  ["ctrl+shift+pagedown"] = "tab:move-right",
})

core.add_thread(function()
  coroutine.yield(0)   
  M.bootstrap()
  
  require "X.core.tab.session"
end)

local StatusView = require "core.views.statusview"
local _orig_get_items = StatusView.get_items

if _orig_get_items then
  function StatusView:get_items()
    local left, right = _orig_get_items(self)

    local total = M.get_count()
    if total < 2 then
      return left, right
    end

    local idx = M.get_index(M.active_id) or 1
    right = { table.unpack(right or {}) }
    table.insert(right, StatusView.sep)
    table.insert(right, style.dim)
    table.insert(right, "[")
    table.insert(right, style.accent)
    table.insert(right, idx)
    table.insert(right, style.dim)
    table.insert(right, "/")
    table.insert(right, total)
    table.insert(right, "]")
    table.insert(right, style.text)

    return left, right
  end
end

return M