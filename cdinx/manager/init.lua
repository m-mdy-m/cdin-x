-- CDIN-X extension manager — public facade.
local core     = require "core"
local fs       = require "core.fs"
local config   = require "cdinx.config"

local Util      = require "cdinx.manager.util"
local Registry  = require "cdinx.manager.registry"
local State     = require "cdinx.manager.state"
local Catalog   = require "cdinx.manager.catalog"
local Runtime   = require "cdinx.manager.runtime"
local Lifecycle = require "cdinx.manager.lifecycle"

local Manager = {
  available = {},
  installed = {},
  sources = {},
}

local ctx = {
  available = Manager.available,
  sources = Manager.sources,
  installed = Manager.installed,
  -- Plugins the host already loaded before cdin-x ran. The mandatory
  -- bundle is the normal case: a cdin build ships vim, the host's loader
  -- has already initialised it, and cdin-x must not initialise it again.
  provided = {},
  state = { disabled = {}, lock = {} },
  registry_external = false,
}

local bootstrapped = false

-- ── roots ──────────────────────────────────────────────────────────────

local function user_extensions_root()
  return config.extension_dir
end
local function builtin_root()
  return Util.join(config.site_dir, "X")
end

local function current_roots()
  return {
    registry  = Registry.registry_root(config),
    installed = user_extensions_root(),
    builtin   = builtin_root(),
  }
end

local function merge_sources()
  local all = Catalog.merge_sources(ctx, current_roots())
  -- A plugin the host already loaded is not a plugin the manager offers:
  -- it is already running, so listing it as installable would invite the
  -- user to "install" something that is present, and loading it would be
  -- the double-init described on collect_provided. Deps still resolves it
  -- as a satisfied dependency, so integrations that need vim keep working.
  for name in pairs(ctx.provided or {}) do
    all[name] = nil
    ctx.sources[name] = "provided"
  end
  Manager.available = all
  Manager.sources = ctx.sources
  return all
end

local function save_state()
  return State.save(config, ctx.state)
end

local function is_disabled(name)
  return ctx.state.disabled[name] == true
end

-- ── registry ───────────────────────────────────────────────────────────

function Manager.ensure_registry(force)
  local ok, err = Registry.ensure(config, ctx)
  if not ok then return false, err end
  if force then
    local refreshed, refresh_err = Registry.refresh(config)
    if not refreshed then return false, refresh_err end
  end
  merge_sources()
  return true
end

-- Lets an extension that knows how to fetch the catalog (the git extension)
-- supply the one operation core refuses to implement itself. With none
-- registered, refresh_registry reports that it is unavailable.
function Manager.set_registry_syncer(fn)
  Registry.set_syncer(fn)
end

function Manager.refresh_registry()
  local ok, err = Registry.ensure(config, ctx)
  if not ok then return false, err end
  local refreshed, refresh_err = Registry.refresh(config)
  if not refreshed then return false, refresh_err end
  merge_sources()
  return true
end

-- ── host-provided plugins ──────────────────────────────────────────────

local function collect_provided()
  local provided = {}
  local ok, plugins = pcall(require, "core.plugins")
  if ok and plugins and plugins.loaded then
    for name in pairs(plugins.loaded) do
      provided[name] = true
    end
  end
  ctx.provided = provided
  return provided
end

-- ── boot ───────────────────────────────────────────────────────────────

function Manager.bootstrap()
  if bootstrapped then return true end

  ctx.state = State.load(config)
  collect_provided()
  merge_sources()

  local ok = Runtime.load_all(ctx, is_disabled)
  if not ok then
    bootstrapped = false
    return false
  end

  bootstrapped = true
  return true
end

-- ── catalog / listing ──────────────────────────────────────────────────

function Manager.scan()
  return merge_sources()
end

function Manager.list()
  merge_sources()
  return Manager.available
end

function Manager.list_builtin()
  return Catalog.list_by_source(ctx, "builtin")
end

function Manager.list_local()
  merge_sources()
  return Catalog.list_by_source(ctx, "installed")
end

function Manager.list_loaded()
  return Manager.installed
end

function Manager.search(query)
  merge_sources()
  return Catalog.search(ctx, query)
end

function Manager.get(name)
  merge_sources()
  return Manager.available[name]
end

function Manager.get_status(name)
  local plugin = Manager.available[name]
  if not plugin then return "missing" end
  if plugin._source == "builtin" then return "builtin" end
  if plugin._source == "installed" then
    if is_disabled(name) then return "disabled" end
    return "installed"
  end
  return "available"
end

function Manager.get_readme(name)
  local plugin = Manager.available[name]
  if not plugin then return nil end
  if plugin._single_file then return nil end
  local path = Util.join(plugin._path, "README.md")
  if fs.is_file(path) then return path end
  return nil
end

function Manager.open_readme(name)
  local plugin = Manager.available[name]
  if not plugin then return false, "unknown extension: " .. tostring(name) end

  local path = Manager.get_readme(name)
  if path then
    core.root_view:open_doc(core.open_doc(path))
    return true
  end

  if plugin._single_file then
    core.log("%s: %s", plugin.name or name, plugin.description or "(no description)")
    return true
  end

  return false, "README not found"
end

function Manager.get_essential_names()
  merge_sources()
  local names = {}
  for name, plugin in pairs(Manager.available) do
    if plugin.essential == true then
      names[#names + 1] = name
    end
  end
  table.sort(names)
  return names
end

function Manager.is_essential(name)
  local plugin = Manager.available[name]
  return plugin ~= nil and plugin.essential == true
end

-- ── runtime (load/unload) ──────────────────────────────────────────────

function Manager.load_plugin(name)
  return Runtime.load_plugin(ctx, name)
end

function Manager.unload_plugin(name)
  return Runtime.unload_plugin(ctx, name)
end

-- ── lifecycle ──────────────────────────────────────────────────────────

function Manager.install(name)
  merge_sources()
  local ok, result, plugin_type = Lifecycle.install(ctx, config, name, Manager.ensure_registry, save_state)
  if not ok then return false, result end
  merge_sources()
  if result == "copied" and plugin_type ~= "theme" then
    local loaded, load_err = Runtime.load_plugin(ctx, name)
    if not loaded then return false, "installed but load failed: " .. tostring(load_err) end
  end
  return true
end

function Manager.install_local(path)
  local ok, meta_or_err = Lifecycle.install_local(ctx, config, path, Manager.install, save_state)
  if not ok then return false, meta_or_err end
  merge_sources()
  local meta = meta_or_err
  if meta.type ~= "theme" then
    local loaded, load_err = Runtime.load_plugin(ctx, meta.name)
    if not loaded then return false, "installed but load failed: " .. tostring(load_err) end
  end
  return true
end

function Manager.update(name)
  merge_sources()
  local ok, err = Manager.ensure_registry(true)
  if not ok then return false, err end
  merge_sources()

  local success, result = Lifecycle.update(ctx, config, name, Registry.registry_root(config))
  save_state()
  merge_sources()
  return success, result
end

function Manager.clean(dry_run)
  merge_sources()
  local ok, result = Lifecycle.clean(ctx, user_extensions_root(), Registry.registry_root(config), dry_run)
  if dry_run then return ok, result end
  save_state()
  merge_sources()
  return ok, result
end

function Manager.enable(name)
  return Lifecycle.enable(ctx, name, save_state)
end

function Manager.disable(name)
  return Lifecycle.disable(ctx, name, save_state)
end

function Manager.uninstall(name)
  local ok, err = Lifecycle.uninstall(ctx, name, save_state)
  if not ok then return false, err end
  merge_sources()
  return true
end

return Manager
