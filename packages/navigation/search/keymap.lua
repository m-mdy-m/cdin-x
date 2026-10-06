local keymap = require "core.input.keymap"

local M = {}

local MAP = {
  ["ctrl+f"]         = "find-replace:find",
  ["shift+r"]        = "find-replace:previous-find",
  ["ctrl+shift+h"]   = "find-replace:clear-highlight",
  ["f4"]             = "find-replace:repeat-find",
  -- Ctrl+D is owned by doc:select-word too. keymap.add() prepends, so the
  -- search takes it while a match is selected (its predicate holds) and the
  -- core's doc:select-word, still behind it in the chain, takes it otherwise.
  --
  -- Never pass `overwrite` here. It replaces the WHOLE chain for a stroke,
  -- and up / down / return below are also the document cursor, the command
  -- line's submit and the autocomplete popup: overwriting them left the
  -- document with dead arrows and the ":" prompt with a dead Enter.
  ["ctrl+d"]         = "find-replace:select-next",

  ["f5"]           = "project-search:refresh",
  ["ctrl+shift+f"] = "project-search:find",
  ["up"]           = "project-search:select-previous",
  ["down"]         = "project-search:select-next",
  ["return"]       = "project-search:open-selected",
}

function M.register()
  keymap.add(MAP)
end

function M.unregister()
  keymap.remove(MAP)
end

return M
