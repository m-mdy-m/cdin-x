-- The panel's keys.
--
-- Two maps, because the panel has two modes. While browsing, letters are
-- commands and the footer says so. While searching, letters are text and the
-- ones bound here are the three that must still work: backspace, return,
-- escape. The bindings are installed and removed as a pair with the commands
-- in commands.lua, so a panel that never opens leaves no keys behind.
local keymap = require "core.input.keymap"

local M = {}

local BROWSING = {
  ["j"]        = "pluginmanager:select-next",
  ["down"]     = "pluginmanager:select-next",
  ["k"]        = "pluginmanager:select-previous",
  ["up"]       = "pluginmanager:select-previous",
  ["space"]    = "pluginmanager:toggle-cursor",
  ["return"]   = "pluginmanager:activate-cursor",
  ["x"]        = "pluginmanager:toggle-cursor",
  ["i"]        = "pluginmanager:install-cursor",
  ["u"]        = "pluginmanager:uninstall-cursor",
  ["d"]        = "pluginmanager:open-details",
  ["r"]        = "pluginmanager:refresh",
  ["?"]        = "pluginmanager:catalog-status",
  ["ctrl+r"]   = "pluginmanager:update-catalog",
  ["/"]        = "pluginmanager:search",
  ["ctrl+f"]   = "pluginmanager:search",
  ["["]        = "pluginmanager:narrow",
  ["]"]        = "pluginmanager:widen",
  ["escape"]   = "pluginmanager:close",
}

-- The stroke that opens the panel. Shift+M is vim's normal-mode key and is
-- bound by with/plugin-manager.lua through vim's own registry; it is NOT bound here,
-- because a global shift+m is also the keystroke for typing a capital M, and
-- bound globally it opened the panel from insert mode and from the ":" prompt.
-- ctrl+shift+M works everywhere, and is why the panel is reachable in a
-- build with nothing installed.
--
-- ctrl+shift+l opens the log. The panel's own messages ("see log,
-- ctrl+shift+l") send people there, so the key is bound here too rather than
-- relying on the host's binding being present in every build.
local GLOBAL = {
  ["ctrl+shift+m"]  = "pluginmanager:toggle",
  ["ctrl+shift+l"]  = "core:open-log",
}

local SEARCHING = {
  ["backspace"] = "pluginmanager:search-delete",
  ["return"]    = "pluginmanager:search-submit",
  ["escape"]    = "pluginmanager:search-stop",
}

function M.register()
  keymap.add(GLOBAL)
  keymap.add(BROWSING)
  -- Prepended, and it wins over the browsing entries on the same strokes,
  -- which is the point: escape ends the search before it closes the panel.
  keymap.add(SEARCHING)
end

function M.unregister()
  keymap.remove(SEARCHING)
  keymap.remove(BROWSING)
  keymap.remove(GLOBAL)
end

M.BROWSING  = BROWSING
M.GLOBAL    = GLOBAL
M.SEARCHING = SEARCHING

return M
