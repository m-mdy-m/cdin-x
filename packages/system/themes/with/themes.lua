-- Persist the theme chosen with the switcher into the session.
--
-- This is a `with` entry: it exists only while both `themes` and `session` are
-- active, and goes away when either one does. It has no commands and no keys --
-- only a subscription -- and it declares no dependency either, because a `with`
-- file is by definition only ever run when its partner is already up.
--
-- It reaches `workspace.session.api` rather than the `workspace` package root
-- because that is where the session keeps its public surface, and a `with` file is
-- the one place allowed to: the whole point of the mechanism is the wiring between
-- two packages that cannot know about each other.
--
-- The switcher is a *feature* of this package, so it is reached as
-- `themes.features.switcher` and only exists while the feature is on. That is
-- fine: `with` entries go down before features do, so this seam is always torn
-- down while the switcher it is holding is still up.
local switcher = require "themes.features.switcher"

local M = {}

local function on_theme_change(name)
  require("workspace.session.api").set_theme(name)
end

function M.enable()
  switcher.on_change(on_theme_change)
end

function M.disable()
  switcher.off_change(on_theme_change)
end

return M