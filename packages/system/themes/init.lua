-- The themes package: a directory of themes, and a switcher for them.
--
-- The theme root is registered here rather than by the kernel because it belongs
-- to the package: a third-party package that ships themes registers its own, and
-- nothing about the editor's own theme handling needs to know where they came
-- from.
--
-- Timing is the whole constraint here. `config.theme` is applied by the host at
-- style.lua load time, long before any plugin runs, so a root registered later
-- still arrives before the first frame is drawn with the wrong colours -- but it
-- has to be registered before the user can ask for a theme by name, which is
-- what the switcher does.
local themes = require "core.themes"
local Loader = require "cdinx.manager.loader"

local M = {}

--- This package's own directory, from the kernel.
---
--- Not worked out from the module path: a package may be a checkout, a site
--- install or a build's data tree, and `config.site_dir` is only the second of
--- those. The loader is what loaded it, so it is what knows.
local function own_dir()
  return Loader.dir_of("themes")
end

function M.init()
  if M.loaded then return end
  M.loaded = true

  -- `themes.add_root` is handed the directory the themes are in. The host's
  -- layout is fixed -- it reads `<root>/<name>/theme.lua` -- so the ten keep
  -- their own directory names and `themes/` here is only the parent they live
  -- under. Nothing is copied, generated or symlinked to make that work, and a
  -- theme package from anywhere else is registered the same way.
  --
  -- The name is written here rather than read from package.lua, because that is a
  -- data file and cannot be required, and because it is the same string as the
  -- directory: one place to change, not two that have to agree.
  local dir = own_dir()
  if dir then themes.add_root(dir .. "/themes") end
end

function M.unload()
  if not M.loaded then return end
  -- Nothing to undo, and that is a gap rather than a choice: a theme root is a
  -- path the host remembers, and the host has no remove_root to call. So an
  -- unloaded `themes` leaves its ten themes findable by name -- which is
  -- harmless, because `config.theme` is what actually picks one and nothing here
  -- is registered to be undone. A `remove_root` is a CDIN SIDE item.
  M.loaded = false
end

return M