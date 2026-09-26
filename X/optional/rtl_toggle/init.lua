local function plugin_dir()
  local src = debug.getinfo(1, "S").source:match("^@(.+)$")
  return src:match("^(.*)[/\\][^/\\]+$")
end

local M = dofile(plugin_dir() .. "/manifest.lua")
M.config = {}

local loaded = false
function M.init(core, config)
  if loaded then return end
  loaded = true
  require "X.optional.rtl_toggle.impl"
end
function M.unload() end
return M
