-- Session key bindings.
--
-- Note ctrl+shift+d is bound here as well as in cdin's default keymap
-- (to doc:duplicate-lines). keymap.add puts later registrations first, so
-- this one wins and duplicate-lines has to be reached another way. That is
-- pre-existing behaviour, kept as-is here rather than silently changed.
local keymap = require "core.input.keymap"

local M = {}

local MAP = {
  ["ctrl+shift+r"] = "session:open-recent",
  ["ctrl+shift+d"] = "session:open-recent-dirs",
  ["ctrl+alt+s"]   = "session:save",
}

function M.register()
  keymap.add(MAP, true)
end

function M.unregister()
  keymap.remove(MAP)
end

return M
