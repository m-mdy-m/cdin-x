local core   = require "core"
local fs     = require "core.fs"
local config = require "core.x.config"
local Util   = require "core.x.manager.util"
local Deps   = require "core.x.manager.deps"

local Runtime = {}

local function is_runtime_plugin(plugin)
  return plugin and plugin.type ~= "theme"
end

function Runtime.load_plugin(ctx, name)
  local plugin = ctx.available[name]
  if not plugin then return false, "unknown extension: " .. name end
  if plugin.type == "theme" then return true end
  if ctx.installed[name] then return true end

  for _, dep in ipairs(plugin.dependencies or {}) do
    if not ctx.installed[dep] then
      local ok, err = Runtime.load_plugin(ctx, dep)
      if not ok then return false, err end
    end
  end

  local mod
  if plugin._single_file then
    local ok, loaded = pcall(dofile, plugin._path)
    if not ok then return false, tostring(loaded) end
    mod = loaded
  else
    local init_path = Util.join(plugin._path, "init.lua")
    if not fs.is_file(init_path) then
      return false, "missing init.lua: " .. init_path
    end

    local old_package_path = package.path
    package.path = plugin._path .. "/?.lua;" .. plugin._path .. "/?/init.lua;" .. old_package_path
    local ok, loaded = pcall(dofile, init_path)
    package.path = old_package_path
    if not ok then return false, tostring(loaded) end
    mod = loaded
  end

  if type(mod) ~= "table" then
    return false, "plugin must return a table"
  end

  if mod.init then
    local init_ok, init_err = pcall(mod.init, core, config)
    if not init_ok then
      return false, "init failed: " .. tostring(init_err)
    end
  end

  ctx.installed[name] = mod
  return true
end

function Runtime.unload_plugin(ctx, name)
  local mod = ctx.installed[name]
  if not mod then return true end

  if mod.unload then
    local ok, err = pcall(mod.unload)
    if not ok then
      return false, "unload failed: " .. tostring(err)
    end
  end

  ctx.installed[name] = nil
  return true
end

function Runtime.load_all(ctx, is_disabled)
  local targets = {}
  for name, plugin in pairs(ctx.available) do
    if plugin._source == "builtin" then
      targets[#targets + 1] = name
    elseif plugin._source == "installed" and not is_disabled(name) then
      targets[#targets + 1] = name
    end
  end

  local ordered, err = Deps.topological_order(ctx, targets)
  if not ordered then
    core.log("cdin-x: load order error: %s", err)
    return false
  end

  for _, name in ipairs(ordered) do
    local plugin = ctx.available[name]
    if is_runtime_plugin(plugin) then
      local ok, load_err = Runtime.load_plugin(ctx, name)
      if not ok then
        core.log("cdin-x: failed to load %s: %s", name, load_err)
      end
    end
  end

  return true
end

return Runtime
