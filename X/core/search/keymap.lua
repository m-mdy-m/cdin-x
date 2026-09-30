local keymap = require "core.input.keymap"

local M = {}

local MAP = {
  ["ctrl+f"]         = "find-replace:find",
  ["shift+r"]        = "find-replace:previous-find",
  ["ctrl+shift+h"]   = "find-replace:clear-highlight",
  ["f4"]             = "find-replace:repeat-find",
  -- Ctrl+D is owned by doc:select-word too. A list is a fallback chain, not
  -- an override: the commands are tried in order and the first one whose
  -- predicate holds runs. So the search takes it while a match is selected,
  -- and select-word takes it the rest of the time. The `true` below replaces
  -- whatever stroke the default keymap already had, which is what we want —
  -- adding without it would prepend and leave the old chain in front.
  ["ctrl+d"]         = { "find-replace:select-next", "doc:select-word" },

  ["f5"]           = "project-search:refresh",
  ["ctrl+shift+f"] = "project-search:find",
  ["up"]           = "project-search:select-previous",
  ["down"]         = "project-search:select-next",
  ["return"]       = "project-search:open-selected",
}

function M.register()
  keymap.add(MAP, true)
end

function M.unregister()
  keymap.remove(MAP)
end

return M
