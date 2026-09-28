local keymap = require "core.input.keymap"

local M = {}

local MAP = {
  ["ctrl+f"]         = "find-replace:find",
  ["shift+r"]        = "find-replace:previous-find",
  ["ctrl+shift+h"]   = "find-replace:clear-highlight",
  ["f4"]             = "find-replace:repeat-find",
  -- prepended so it wins over the default doc:select-word, which Ctrl+D
  -- also owns
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
