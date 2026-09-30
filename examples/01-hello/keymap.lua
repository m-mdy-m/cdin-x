-- The key binding.
--
-- Keys map a keystroke to a command *name*, never to a function. That is what
-- lets the command palette find and run this without knowing the plugin
-- exists — and it is why removing a binding and removing a command are two
-- separate things to get right.
local keymap = require "core.input.keymap"

local M = {}

local KEYS = { ["ctrl+alt+h"] = "hello:say" }

function M.register()
  keymap.add(KEYS, true)
end

function M.unregister()
  -- The same table, not a copy. Unregistering matches by identity, so a
  -- rebuilt table removes nothing and leaves the binding live.
  keymap.remove(KEYS)
end

return M
