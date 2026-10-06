-- Tab commands. Registered and unregistered as a unit so disabling the
-- plugin gives the command palette and every keymap its names back.
local command = require "core.input.command"
local core    = require "core"
local T       = require "workspace.tab.manager"

local M = {}

local MAP = {
  -- ── lifecycle ────────────────────────────────────────────────────────────
  ["tab:new"]           = function() T.create() end,
  ["tab:close"]         = function() T.close(T.active_id, false) end,
  ["tab:close-force"]   = function() T.close(T.active_id, true) end,
  ["tab:close-others"]  = function() T.close_others() end,
  ["tab:close-all"]     = function() T.close_all() end,
  ["tab:reopen-closed"] = function() T.reopen_closed() end,
  ["tab:duplicate"]     = function() T.duplicate() end,
  ["tab:pin"]           = function() T.pin(T.active_id) end,

  ["tab:rename"] = function()
    local tab = T.get_active()
    if not tab then return end
    core.command_view:enter("Rename Tab", function(name)
      if name and name ~= "" then T.rename(tab.id, name) end
    end, nil, nil, tab.name)
  end,

  -- ── navigation ───────────────────────────────────────────────────────────
  ["tab:next"]  = function() T.next() end,
  ["tab:prev"]  = function() T.prev() end,
  ["tab:first"] = function() T.first() end,
  ["tab:last"]  = function() T.last() end,

  ["tab:go-1"] = function() T.go_to(1) end,
  ["tab:go-2"] = function() T.go_to(2) end,
  ["tab:go-3"] = function() T.go_to(3) end,
  ["tab:go-4"] = function() T.go_to(4) end,
  ["tab:go-5"] = function() T.go_to(5) end,
  ["tab:go-6"] = function() T.go_to(6) end,
  ["tab:go-7"] = function() T.go_to(7) end,
  ["tab:go-8"] = function() T.go_to(8) end,
  ["tab:go-9"] = function() T.go_to(9) end,

  -- ── reorder ──────────────────────────────────────────────────────────────
  ["tab:move-left"] = function()
    local idx = T.get_index(T.active_id)
    if idx then T.move(T.active_id, idx - 1) end
  end,
  ["tab:move-right"] = function()
    local idx = T.get_index(T.active_id)
    if idx then T.move(T.active_id, idx + 1) end
  end,
}

local NAMES = (function()
  local out = {}
  for name in pairs(MAP) do out[#out + 1] = name end
  table.sort(out)
  return out
end)()

function M.register()
  command.add(nil, MAP, true)
end

function M.unregister()
  command.remove(NAMES)
end

return M
