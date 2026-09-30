-- gc, in normal mode.
--
-- The maps are kept in module-level locals and handed back by reference on
-- unregister. The registry matches by identity: it removes a key only if the
-- value is still the one you registered. That is what lets two plugins both
-- answer to the same key, and lets the later one's unload leave the earlier
-- one's registration alone.

local core     = require "core"
local registry = require "X.core.vim.registry"

local M = {}

-- "gc" rather than something obvious. Every key in vim mode is a negotiation
-- with vim core and with every other integration, and a plugin that picks a
-- key without looking is the reason two of them stop working. Check what's
-- taken — this catalog is small enough to read.
local gmap = {
  ["gc"] = function()
    local dv = core.active_docview()
    if not dv then return false end

    local words = 0
    for i = 1, #dv.doc.lines do
      for _ in (dv.doc.lines[i] or ""):gmatch("%S+") do words = words + 1 end
    end

    core.log("%d words", words)
  end,
}

function M.register()
  registry.register_gmap(gmap)
end

function M.unregister()
  -- The same table, not a rebuilt one. A fresh table removes nothing.
  registry.unregister_gmap(gmap)
end

return M
