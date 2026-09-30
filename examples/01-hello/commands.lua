-- The command. Commands are registered by *name*, with an optional
-- predicate saying when they apply.
--
-- The predicate is the first argument, and it has three forms:
--   nil             always available
--   a string        a module path returning a function
--   a class table   available while the active view is an instance of it
--
-- "core.views.docview" is the host's document view, which is the usual
-- answer for anything that touches a document.

local core    = require "core"
local command = require "core.input.command"

local M = {}

local NAMES = { "hello:say" }

local MAP = {
  ["hello:say"] = function()
    core.log("hello")
  end,
}

function M.register()
  -- The third argument permits overwriting an existing registration. Pass it
  -- when you mean to replace something, leave it off when you mean to own the
  -- name — without it, a collision is an error rather than a silent loss.
  command.add(nil, MAP, true)
end

function M.unregister()
  -- Names, not the map: remove() drops exactly the commands this plugin owns
  -- and leaves everyone else's alone.
  command.remove(NAMES)
end

return M
