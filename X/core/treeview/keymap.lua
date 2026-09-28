-- Treeview key bindings. Register/unregister are explicit so disabling the
-- plugin gives the strokes back — Up/Down/Return/Left/Right and Ctrl+R are
-- shared with the document view, so leaving them bound after the treeview
-- is gone would be actively wrong.
local keymap = require "core.input.keymap"

local M = {}

local MAP = {
  ["f2"]               = { "treeview:toggle", "treeview:focus-and-refresh" },
  ["f3"]               = "treeview:focus",
  ["ctrl+\\"]          = "treeview:toggle",
  ["ctrl+shift+e"]     = "treeview:focus",
  ["ctrl+shift+n"]     = "treeview:new-file",
  ["ctrl+shift+alt+n"] = "treeview:new-directory",
  ["up"]               = "treeview:select-previous",
  ["down"]             = "treeview:select-next",
  ["return"]           = "treeview:open-cursor-item",
  ["keypad enter"]     = "treeview:open-cursor-item",
  ["left"]             = "treeview:collapse-or-parent",
  ["right"]            = "treeview:expand-or-child",
  ["ctrl+r"]           = "treeview:rename-key",
  ["delete"]           = "treeview:delete-key",
  ["ctrl+shift+r"]     = "treeview:refresh-key",
}

function M.register()
  keymap.add(MAP, true)
end

function M.unregister()
  keymap.remove(MAP)
end

return M
