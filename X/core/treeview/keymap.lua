-- Treeview key bindings.
local keymap = require "core.input.keymap"

local M = {}

local MAP = {
  ["f2"]               = { "treeview:toggle", "treeview:focus-and-refresh" },
  ["f3"]               = "treeview:focus",
  ["ctrl+\\"]          = "treeview:toggle",
  ["ctrl+shift+e"]     = "treeview:focus",
  ["ctrl+shift+n"]     = "treeview:new-file",
  ["ctrl+shift+alt+n"] = "treeview:new-directory",
  ["ctrl+shift+r"]     = "treeview:refresh-key",
}

local SHARED = {
  ["up"]           = "treeview:select-previous",
  ["down"]         = "treeview:select-next",
  ["return"]       = "treeview:open-cursor-item",
  ["keypad enter"] = "treeview:open-cursor-item",
  ["left"]         = "treeview:collapse-or-parent",
  ["right"]        = "treeview:expand-or-child",
  ["ctrl+r"]       = "treeview:rename-key",
  ["delete"]       = "treeview:delete-key",
}

function M.register()
  keymap.add(MAP)
  keymap.add(SHARED)
end

function M.unregister()
  keymap.remove(SHARED)
  keymap.remove(MAP)
end

M.MAP    = MAP
M.SHARED = SHARED

return M