-- A single-file essential plugin whose only job is to mark the CDIN-X
-- built-in bundle as present and installed, matching the core/core/
-- directory plugin it replaced. 
local M = {
  name = "core",
  version = "0.2.0",
  description = "CDIN built-in core extensions",
  author = "cdin Team",
  license = "MIT",
  category = "core",
  type = "plugin",
  essential = true,
  dependencies = {},
  min_cdin_version = "0.5.0",
  tags = { "essential", "system", "core" },
}

M.config = {}

function M.init(core, config)
  core.log("CDIN core extension bundle active")
end

function M.unload() end

return M
