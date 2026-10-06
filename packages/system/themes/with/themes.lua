-- Persist the theme chosen with the switcher into the session.
--
-- This is a `with` entry: it exists only while both `themes` and `session` are
-- active, and goes away when either one does. It has no commands and no keys --
-- only a subscription -- and it declares no dependency either, because a `with`
-- file is by definition only ever run when its partner is already up.
--
-- It reaches `session.api` rather than `session` because that is where the
-- session keeps its public surface, and a `with` file is the one place allowed
-- to: the whole point of the mechanism is the wiring between two packages that
-- cannot know about each other.
local switcher = require "themes.switcher"

local M = {}

local function on_theme_change(name)
  require("session.api").set_theme(name)
end

function M.enable()
  switcher.on_change(on_theme_change)
end

function M.disable()
  switcher.off_change(on_theme_change)
end

return M