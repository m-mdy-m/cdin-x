-- One command, in a document view.
--
-- The predicate is the string "core.views.docview", and command.add treats a
-- string predicate as a module path: it requires that module and uses the
-- function it returns. So the command is only offered while a document has
-- focus, and the command palette greys it out otherwise instead of failing
-- when somebody picks it anyway.

local core    = require "core"
local command = require "core.input.command"

local M = {}

local NAMES = { "word-count:report" }

local MAP = {
  ["word-count:report"] = function()
    -- The measuring lives in the plugin's own init.lua and is reached
    -- through the returned table, rather than being written a second time
    -- here. A plugin of any size wants exactly this shape: a public surface
    -- on the entry point, and the details behind it.
    --
    -- This require is inside the function on purpose. A top-level one would
    -- run while the catalog is still dofile()ing the entry point, which is
    -- the same cycle the manifest rule exists to prevent.
    local words, lines, chars = require("word-count").stats()

    if not words then
      core.error("No document open")
      return
    end

    core.log("%d words, %d lines, %d characters", words, lines, chars)
  end,
}

function M.register()
  command.add("core.views.docview", MAP, true)
end

function M.unregister()
  command.remove(NAMES)
end

return M
