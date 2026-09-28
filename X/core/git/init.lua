-- Git/VCS support, moved out of cdin core (was data/core/git/).
--
-- data/core is runtime-only; a plain-text editor works with zero
-- knowledge of git, so this whole capability now lives here as a plugin.
--
-- This file is only the manifest and the load point. The module consumers
-- use is api.lua — see the comment there for why it is not this file.
--
-- The manifest is inline rather than in a separate manifest.lua, and
-- nothing is required at the top of the file, so the extension catalog
-- can dofile() this to read the manifest without running any of the
-- plugin's code.
local M = {
  name = "git",
  version = "0.2.0",
  description = "Git status, ignore rules and shared shell recipes",
  author = "cdin Team",
  license = "MIT",
  category = "core",
  type = "plugin",
  essential = false,
  dependencies = {},
  min_cdin_version = "0.5.0",
  tags = { "git", "vcs", "status" },
}

local loaded = false

function M.init(core, config)
  if loaded then return end
  loaded = true
  require("X.core.git.api").register()
  core.log("Git extension loaded")
end

function M.unload()
  if not loaded then return end
  require("X.core.git.api").unregister()
  loaded = false
end

return M
