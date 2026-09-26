-- Metadata (name, version, description, author, license, category,
-- essential, dependencies, tags, etc.) lives in manifest.lua, which the
-- catalog/scanner also reads. This file only adds what's specific to
-- actually running the plugin: its config table and init/unload hooks.
local function plugin_dir()
  local src = debug.getinfo(1, "S").source:match("^@(.+)$")
  return src:match("^(.*)[/\\][^/\\]+$")
end

local M = dofile(plugin_dir() .. "/manifest.lua")
M.config = {}

function M.init(core, config)
  core.log("CDIN core extension bundle active")
end

function M.unload() end
return M
