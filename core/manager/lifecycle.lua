-- Lifecycle mutations on the installed-extension store: copying files in/out
-- of config.extension_dir, flipping the disabled flag, and keeping the lock
-- file in sync. Every function here that changes what's on disk is expected
-- to be followed by the caller re-running Catalog.merge_sources.
local fs       = require "core.fs"
local Manifest = require "core.x.manifest"
local Util     = require "core.x.manager.util"
local Catalog  = require "core.x.manager.catalog"
local Runtime  = require "core.x.manager.runtime"

local Lifecycle = {}

local function install_path_for(config, plugin)
  local base = Util.join(config.extension_dir, plugin.category, plugin.name)
  if plugin._single_file then
    return base .. ".lua"
  end
  return base
end

local function is_disabled(ctx, name)
  return ctx.state.disabled[name] == true
end

-- install() expects the caller to have already ensured the registry and
-- merged sources; `resolve` is a callback used to re-look-up a plugin after
-- Manager pulls the registry for a name it doesn't yet know about.
function Lifecycle.install(ctx, config, name, ensure_registry, save_state, stack)
  local plugin = ctx.available[name]
  if not plugin then
    local ok, err = ensure_registry(false)
    if not ok then return false, err end
    plugin = ctx.available[name]
  end
  if not plugin then return false, "extension not found in catalog: " .. name end

  if plugin._source == "builtin" then
    return true, "already built-in"
  end
  if plugin._source == "installed" then
    if plugin.type ~= "theme" and not ctx.installed[name] and not is_disabled(ctx, name) then
      Runtime.load_plugin(ctx, name)
    end
    return true
  end

  stack = stack or {}
  if stack[name] then return false, "dependency cycle: " .. name end
  stack[name] = true
  for _, dep in ipairs(plugin.dependencies or {}) do
    local ok, err = Lifecycle.install(ctx, config, dep, ensure_registry, save_state, stack)
    if not ok then return false, "dependency " .. dep .. ": " .. tostring(err) end
  end
  stack[name] = nil

  local src = plugin._path
  local dst = install_path_for(config, plugin)
  fs.mkdir(fs.dirname(dst))

  if fs.exists(dst) then
    fs.rm(dst)
  end
  local ok, err = fs.copy(src, dst)
  if not ok then return false, err end

  ctx.state.disabled[name] = nil
  ctx.state.lock[name] = {
    version = plugin.version or "",
    installed_at = os.date("!%Y-%m-%dT%H:%M:%SZ"),
  }
  save_state()

  return true, "copied", plugin.type
end

function Lifecycle.install_local(ctx, config, path, install_fn, save_state)
  path = fs.abs(path)

  local meta, err, single_file
  if fs.is_dir(path) then
    meta, err = Manifest.load(path)
    single_file = false
  elseif fs.is_file(path) and path:match("%.lua$") then
    local ok
    ok, meta = pcall(dofile, path)
    if not ok then meta, err = nil, tostring(meta) end
    single_file = true
  else
    return false, "not a directory or .lua file: " .. tostring(path)
  end
  if not meta then return false, err end

  local ok, errors = Manifest.validate(meta)
  if not ok then return false, table.concat(errors, "; ") end
  meta.name = meta.name or fs.basename(path):gsub("%.lua$", "")
  meta._single_file = single_file

  for _, dep in ipairs(meta.dependencies or {}) do
    local existing = ctx.available[dep]
    if not existing or (existing._source ~= "builtin" and existing._source ~= "installed") then
      local ok_dep, dep_err = install_fn(dep)
      if not ok_dep then
        return false, "dependency " .. dep .. ": " .. tostring(dep_err)
      end
    end
  end

  local dst = install_path_for(config, meta)
  fs.mkdir(fs.dirname(dst))
  if fs.exists(dst) then fs.rm(dst) end
  local copied, copy_err = fs.copy(path, dst)
  if not copied then return false, copy_err end

  ctx.state.lock[meta.name] = {
    version = meta.version or "",
    installed_at = os.date("!%Y-%m-%dT%H:%M:%SZ"),
  }
  save_state()

  return true, meta
end

function Lifecycle.update(ctx, config, name, registry_root)
  local names
  if name then
    names = { name }
  else
    names = {}
    for n, plugin in pairs(ctx.available) do
      if plugin._source == "installed" then names[#names + 1] = n end
    end
    table.sort(names)
  end

  local updated, errors = {}, {}
  for _, n in ipairs(names) do
    local installed_plugin = ctx.available[n]
    if not installed_plugin or installed_plugin._source ~= "installed" then
      errors[#errors + 1] = n .. ": not installed"
    else
      local locked = ctx.state.lock[n]
      local registry_plugin = Catalog.scan_root(registry_root, "registry")[n]
      if not registry_plugin then
        -- Not in the registry (e.g. installed via install_local) — nothing to compare against.
      elseif locked and locked.version == (registry_plugin.version or "") then
        -- Already at the latest known version; nothing to do.
      else
        local src = registry_plugin._path
        local dst = install_path_for(config, installed_plugin)
        local was_loaded = ctx.installed[n] ~= nil
        if was_loaded then Runtime.unload_plugin(ctx, n) end
        fs.rm(dst)
        local copied, copy_err = fs.copy(src, dst)
        if not copied then
          errors[#errors + 1] = n .. ": " .. tostring(copy_err)
        else
          ctx.state.lock[n] = {
            version = registry_plugin.version or "",
            installed_at = os.date("!%Y-%m-%dT%H:%M:%SZ"),
          }
          updated[#updated + 1] = n
          if was_loaded and not is_disabled(ctx, n) then
            Runtime.load_plugin(ctx, n)
          end
        end
      end
    end
  end

  return #errors == 0, { updated = updated, errors = errors }
end

-- Finds installed extensions no longer reachable from anything: not a
-- dependency of any other installed extension, and no longer in the registry.
function Lifecycle.clean(ctx, user_extensions_root, registry_root, dry_run)
  local depended_on = {}
  for _, plugin in pairs(ctx.available) do
    if plugin._source == "installed" then
      for _, dep in ipairs(plugin.dependencies or {}) do
        depended_on[dep] = true
      end
    end
  end

  local on_disk = Catalog.scan_root(user_extensions_root, "installed")

  local orphaned = {}
  for name, plugin in pairs(on_disk) do
    if not plugin.essential and not depended_on[name] then
      local still_in_registry = Catalog.scan_root(registry_root, "registry")[name] ~= nil
      if not still_in_registry then
        orphaned[#orphaned + 1] = name
      end
    end
  end
  table.sort(orphaned)

  if dry_run then
    return true, orphaned, on_disk
  end

  local removed, errors = {}, {}
  for _, name in ipairs(orphaned) do
    local plugin = on_disk[name]
    if ctx.installed[name] then Runtime.unload_plugin(ctx, name) end
    local ok, err = fs.rm(plugin._path)
    if not ok then
      errors[#errors + 1] = name .. ": " .. tostring(err)
    else
      ctx.state.lock[name] = nil
      ctx.state.disabled[name] = nil
      removed[#removed + 1] = name
    end
  end
  return #errors == 0, { removed = removed, errors = errors }
end

function Lifecycle.enable(ctx, name, save_state)
  local plugin = ctx.available[name]
  if not plugin then return false, "unknown extension: " .. name end
  if plugin._source == "builtin" then return true end
  if plugin._source ~= "installed" then return false, "extension is not installed" end

  ctx.state.disabled[name] = nil
  save_state()
  local ok, err = Runtime.load_plugin(ctx, name)
  if not ok then return false, err end
  return true
end

function Lifecycle.disable(ctx, name, save_state)
  local plugin = ctx.available[name]
  if not plugin then return false, "unknown extension: " .. name end
  if plugin._source == "builtin" or plugin.essential then
    return false, "essential extension cannot be disabled"
  end
  if plugin._source ~= "installed" then
    return false, "extension is not installed"
  end

  for other_name, other in pairs(ctx.available) do
    if other_name ~= name and other._source == "installed" and not is_disabled(ctx, other_name) then
      for _, dep in ipairs(other.dependencies or {}) do
        if dep == name then
          return false, "cannot disable " .. name .. ": required by " .. other_name
        end
      end
    end
  end

  local ok, err = Runtime.unload_plugin(ctx, name)
  if not ok then return false, err end
  ctx.state.disabled[name] = true
  save_state()
  return true
end

function Lifecycle.uninstall(ctx, name, save_state)
  local plugin = ctx.available[name]
  if not plugin then return false, "unknown extension: " .. name end
  if plugin._source == "builtin" or plugin.essential then
    return false, "essential extension cannot be removed: " .. name
  end
  if plugin._source ~= "installed" then
    return false, "extension is not installed: " .. name
  end

  -- Do not remove a dependency while another installed extension uses it.
  for other_name, other in pairs(ctx.available) do
    if other_name ~= name and other._source == "installed" then
      for _, dep in ipairs(other.dependencies or {}) do
        if dep == name then
          return false, "cannot remove " .. name .. ": required by " .. other_name
        end
      end
    end
  end

  local ok, err = Lifecycle.disable(ctx, name, save_state)
  if not ok and ctx.installed[name] then return false, err end

  local path = (plugin._source == "installed") and plugin._path or nil
  if path and fs.exists(path) then
    local rm_ok, rm_err = fs.rm(path)
    if not rm_ok then return false, rm_err end
  end
  ctx.state.disabled[name] = nil
  ctx.state.lock[name] = nil
  save_state()
  return true
end

Lifecycle.install_path_for = install_path_for

return Lifecycle
