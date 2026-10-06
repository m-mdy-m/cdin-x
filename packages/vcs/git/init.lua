-- Git/VCS support, moved out of the editor runtime.
--
-- The editor runtime is runtime-only; a plain-text editor works with zero
-- knowledge of git, so this whole capability now lives here as a package.
--
-- This file is the load point. The module consumers use is api.lua -- see the
-- comment there for why it is not this file.
--
-- The manifest is package.lua, which the catalog reads without running anything
-- here, so this file's requires may sit at the top whenever the order suits.
local M = {}

local loaded = false

function M.init(core, config)
  if loaded then return end
  loaded = true
  require("git.api").register()
  core.log("Git extension loaded")
end

function M.unload()
  if not loaded then return end
  require("git.api").unregister()
  loaded = false
end

return M