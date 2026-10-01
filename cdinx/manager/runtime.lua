local core   = require "core"
local fs     = require "core.fs"
local config = require "cdinx.config"
local Util   = require "cdinx.manager.util"
local Deps   = require "cdinx.manager.deps"
local Loader = require "cdinx.manager.loader"

local Runtime = {}

local function is_runtime_plugin(plugin)
  return plugin and plugin.type ~= "theme"
end

function Runtime.load_plugin(ctx, name)
  -- Installed extensions require "X.…" modules that live in the extension
  -- store without the X/ prefix; see manager/loader.lua. Idempotent.
  Loader.ensure(config.extension_dir)

  -- The host already initialised this one. Loading it again would run its
  -- registrations a second time; see collect_provided in manager/init.lua.
  if Deps.is_provided(ctx, name) then return true end

  local plugin = ctx.available[name]
  if not plugin then return false, "unknown extension: " .. name end
  if plugin.type == "theme" then return true end
  if ctx.installed[name] then return true end

  for _, dep in ipairs(plugin.dependencies or {}) do
    if not ctx.installed[dep] and not Deps.is_provided(ctx, dep) then
      -- A dependency that is only *listed* in the catalog has no files to
      -- load; say so instead of failing later with "missing init.lua".
      if not Deps.is_usable(ctx, dep) then
        return false, "dependency '" .. dep .. "' is not installed"
      end
      local ok, err = Runtime.load_plugin(ctx, dep)
      if not ok then return false, "dependency '" .. dep .. "': " .. tostring(err) end
    end
  end

  -- Optional dependencies: load them first if they are there, carry on
  -- without them if they are not.
  for _, dep in ipairs(plugin.optional_dependencies or {}) do
    if not ctx.installed[dep] and not Deps.is_provided(ctx, dep)
    and Deps.is_usable(ctx, dep) and not ctx.state.disabled[dep] then
      Runtime.load_plugin(ctx, dep)
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
    if Deps.is_provided(ctx, name) then
      -- already running in the host
    elseif plugin._source == "builtin" then
      targets[#targets + 1] = name
    elseif plugin._source == "installed" and not is_disabled(name) then
      targets[#targets + 1] = name
    end
  end

  local ordered, skipped = Deps.topological_order(ctx, targets)

  -- Unmet dependencies are a per-plugin problem, never a reason to abort the
  -- manager: report each one, load everything else.
  local skipped_names = {}
  for name in pairs(skipped) do skipped_names[#skipped_names + 1] = name end
  table.sort(skipped_names)
  for _, name in ipairs(skipped_names) do
    local info = skipped[name]
    core.log("cdin-x: %s was not loaded: %s", name, info.reason)
    if #info.missing > 0 then
      core.log("cdin-x:   fix: install %s (Extensions panel, or re-install %s)",
        table.concat(info.missing, ", "), name)
    end
  end

  for _, name in ipairs(ordered) do
    local plugin = ctx.available[name]
    if is_runtime_plugin(plugin) and not Deps.is_provided(ctx, name) then
      local ok, load_err = Runtime.load_plugin(ctx, name)
      if not ok then
        core.log("cdin-x: failed to load %s: %s", name, load_err)
      end
    end
  end

  return true
end

return Runtime
