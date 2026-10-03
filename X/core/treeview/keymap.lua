-- Treeview key bindings.
--
-- Keystroke spelling here is not free-form: the runtime *builds* the stroke it
-- looks up — `ctrl+` then `alt+` then `altgr+` then `shift+`, then the key's own
-- name — and `keymap.map[stroke]` is an exact string match with no
-- normalisation. So a modifier written out of order, or a key spelled
-- something the input layer cannot produce, is not a near miss: it is a
-- binding nothing will ever fire. Hence `ctrl+alt+shift+n` below, and not
-- `ctrl+shift+alt+n`, which is what this file said for months and which no key
-- press can reach.
--
-- F2 is the log view's key, not the tree's — the log header advertises it for
-- switching between its two streams — so the tree binds the `-key` wrapper,
-- which declines while the log is open. `treeview:toggle` itself stays
-- available everywhere; only this keystroke yields.
local keymap = require "core.input.keymap"

local M = {}

local MAP = {
  ["f2"]                    = "treeview:toggle-key",
  ["f3"]                    = "treeview:focus",
  ["ctrl+\\"]               = "treeview:toggle",
  ["ctrl+shift+e"]          = "treeview:focus",
  ["ctrl+shift+n"]          = "treeview:new-file",
  ["ctrl+alt+shift+n"]      = "treeview:new-directory",
  ["ctrl+shift+r"]          = "treeview:refresh-key",
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