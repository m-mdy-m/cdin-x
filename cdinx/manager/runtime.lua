local Host = require "cdinx.host"
local config = require "cdinx.config"
local Util   = require "cdinx.manager.util"
local Deps   = require "cdinx.manager.deps"
local Loader = require "cdinx.manager.loader"
local Features = require "cdinx.manager.features"

local Runtime = {}

-- The packages `require "<name>.<module>"` will resolve for: the ones that are
-- active, and only those that carry a package.lua. A package without one keeps
-- its path-shaped spelling, and claiming its name as well would give one file
-- two module identities.
--
-- The entry file travels with it because a bundle's `plugins/<name>.lua` shim
-- says `return require("<name>")`, and that has to reach the manifest's entry
-- point, which is not always init.lua.
local function active_roots(ctx)
  local roots, names, entries = {}, {}, {}
  local disabled = ctx.state and ctx.state.disabled
  for name, plugin in pairs(ctx.available) do
    if plugin._package_file then
      names[name] = true
      local active = plugin._source == "builtin"
        or plugin._source == "provided"
        or (plugin._source == "installed" and not (disabled and disabled[name]))
      if active and plugin._path then
        roots[name] = plugin._path
        entries[name] = plugin.entry or "init.lua"
      end
    end
  end
  return roots, names, entries
end

-- Keeps the loader's view of the catalog in step with what is loaded, so a
-- package that goes away stops resolving. Idempotent.
local function sync_loader(ctx)
  local roots, names, entries = active_roots(ctx)
  Loader.ensure(config.extension_dir, roots, names, entries)
end

--- Which features the user has overridden for a package.
---
--- The state file is the only source today, under `features`. It is written by the
--- panel and read here; Phase 7 replaces it with `packages.lua`, and this is the
--- one place that has to change then.
--- @param ctx table
--- @param name string
--- @return table<string, boolean>|nil
local function feature_overrides(ctx, name)
  local state = ctx.state
  if not state then return nil end
  local all = state.features
  if type(all) ~= "table" then return nil end
  local for_package = all[name]
  if type(for_package) ~= "table" then return nil end
  return for_package
end

local function is_runtime_plugin(plugin)
  return plugin and plugin.type ~= "theme"
end

function Runtime.load_plugin(ctx, name)
  -- Installed extensions require "X.…" modules that live in the extension
  -- store without the X/ prefix, and a package with a package.lua requires its
  -- own by name; see manager/loader.lua. Idempotent.
  sync_loader(ctx)

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
    local entry = plugin.entry or "init.lua"
    local init_path = Util.join(plugin._path, entry)
    if not Host.fs.is_file(init_path) then
      return false, "missing " .. entry .. ": " .. init_path
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
    local init_ok, init_err = pcall(mod.init, Host.core, config)
    if not init_ok then
      -- Its modules were loaded to get here, and init() raised halfway. Left in
      -- package.loaded they would be the next attempt's modules -- a half-built
      -- one, whose registrations ran once and whose `loaded` flag is set, so it
      -- would do nothing and look loaded. A package that failed to start must
      -- leave nothing behind.
      Loader.forget(name)
      return false, "init failed: " .. tostring(init_err)
    end
  end

  -- Features go up after init, never before: a feature that registers something
  -- the package's own init depends on would otherwise race it, and one that
  -- fails would take the package down with it. A feature that cannot start is
  -- reported and skipped; the package and its other features stay up.
  if plugin.spec and Features.has_any(plugin.spec) then
    local problems = Features.apply(ctx, name, plugin.spec, feature_overrides(ctx, name))
    for _, problem in ipairs(problems) do
      Host.core.error("cdin-x: %s", problem)
    end
  end

  ctx.installed[name] = mod
  return true
end

function Runtime.unload_plugin(ctx, name)
  local mod = ctx.installed[name]
  if not mod then return true end

  -- Features come down before the package does, and in reverse of the order they
  -- went up. A feature may depend on something its package's init put in place,
  -- so undoing it first is the only order that is right.
  local problems = Features.disable_all(ctx, name)

  if mod.unload then
    local ok, err = pcall(mod.unload)
    if not ok then
      return false, "unload failed: " .. tostring(err)
    end
  end

  for _, problem in ipairs(problems) do
    Host.core.error("cdin-x: %s", problem)
  end

  ctx.installed[name] = nil

  -- Its modules go too, or a reload reuses the tables the registrations were
  -- just made on and nothing undoes them twice.
  Loader.forget(name)
  sync_loader(ctx)
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
    Host.core.log("cdin-x: %s was not loaded: %s", name, info.reason)
    if #info.missing > 0 then
      Host.core.log("cdin-x:   fix: install %s (Extensions panel, or re-install %s)",
        table.concat(info.missing, ", "), name)
    end
  end

  for _, name in ipairs(ordered) do
    local plugin = ctx.available[name]
    if is_runtime_plugin(plugin) and not Deps.is_provided(ctx, name) then
      local ok, load_err = Runtime.load_plugin(ctx, name)
      if not ok then
        Host.core.log("cdin-x: failed to load %s: %s", name, load_err)
      end
    end
  end

  return true
end

return Runtime
