-- Autocomplete key bindings.
--
-- Tab accepts, Up/Down move, Escape dismisses. The commands themselves are
-- predicated on a suggestion being visible, so these strokes fall through
-- to their normal meaning (indent, cursor movement, deselect) whenever the
-- popup is not up.
local keymap = require "core.input.keymap"

local M = {}

local MAP = {
  ["tab"]    = "autocomplete:complete",
  ["up"]     = "autocomplete:previous",
  ["down"]   = "autocomplete:next",
  ["escape"] = "autocomplete:cancel",
}

function M.register()
  keymap.add(MAP)
end

function M.unregister()
  keymap.remove(MAP)
end

return M
