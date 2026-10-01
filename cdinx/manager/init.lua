-- CDIN-X extension manager — public facade.
local core     = require "core"
local fs       = require "core.fs"
local config   = require "cdinx.config"

local Util      = require "cdinx.manager.util"
local Registry  = require "cdinx.manager.registry"
local State     = require "cdinx.manager.state"
local Catalog   = require "cdinx.manager.catalog"
local Runtime   = require "cdinx.manager.runtime"
local Fetch     = require "cdinx.manager.fetch"
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

local function builtin_roots()
  local roots = {}
  if config.bundle_dir then
    roots[#roots + 1] = Util.join(config.bundle_dir, "X")
  end
  roots[#roots + 1] = Util.join(config.site_dir, "X")
  return roots
end

local function current_roots()
  return {
    registry  = Registry.registry_root(config),
    installed = user_extensions_root(),
    builtin   = builtin_roots(),
  }
end

local function merge_sources()
  local all = Catalog.merge_sources(ctx, current_roots())
  Catalog.add_provided(ctx, ctx.provided)
  Manager.available = all
  Manager.sources = ctx.sources
  return all
end

-- Lets Lifecycle refresh the catalog view after it put files on disk, without
-- reaching back into this module.
ctx.rescan = function() merge_sources() end

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
  -- No Registry.ensure() here: "the catalog is not on disk yet" is exactly the
  -- case a refresh exists to fix.
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

  local dir = config.bundle_dir and Util.join(config.bundle_dir, "plugins")
  for _, entry in ipairs(dir and fs.list(dir) or {}) do
    if entry.type == "file" then
      local name = entry.name:match("^(.+)%.lua$")
      if name then
        provided[name] = true
      end
    elseif entry.type == "dir" then
      if fs.is_file(Util.join(dir, entry.name, "init.lua")) then
        provided[entry.name] = true
      end
    end
  end

  ctx.provided = provided
  return provided
end

-- ── boot ───────────────────────────────────────────────────────────────

function Manager.bootstrap()
  if bootstrapped then return true end

  -- Before anything is loaded: an installed extension's first require of its
  -- own modules has to find them in the extension store.
  require("cdinx.manager.loader").ensure(config.extension_dir)

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

-- Which of the roots that hold installable extensions actually exist.
--
-- Named `roots`, not `sources`: Manager.sources is the name -> origin table
-- that merge_sources() keeps replacing, and a function by that name was
-- overwritten on the first scan.
function Manager.roots()
  local roots = current_roots()
  local builtin = 0
  for _, root in ipairs(roots.builtin or {}) do
    if fs.is_dir(root) then builtin = builtin + 1 end
  end
  return {
    registry     = fs.is_file(Util.join(roots.registry, "manifest.lua")),
    installed    = fs.is_dir(roots.installed),
    builtin      = builtin,
    registry_dir = config.registry_dir,
  }
end

-- ── fetching the catalog ───────────────────────────────────────────────

local catalog = { status = "idle", message = nil }

-- "idle" (never tried), "fetching", "ready" or "failed", plus the reason.
function Manager.catalog_state()
  return catalog.status, catalog.message
end

-- Downloads the catalog index (one file) without blocking the editor. Returns true when
-- a fetch is running (or already was), false plus a reason when it could not
-- start. `on_done(ok, err)` runs once, from a thread, when it ends.
function Manager.fetch_catalog(on_done)
  if catalog.status == "fetching" then return true end

  local job, err = Fetch.start(config.registry_dir, config.registry_raw_url)
  if not job then
    catalog.status, catalog.message = "failed", err
    return false, err
  end

  catalog.status, catalog.message = "fetching", nil
  core.add_thread(function()
    while true do
      local ok, perr = Fetch.poll(job)
      if ok ~= nil then
        if ok then
          catalog.status, catalog.message = "ready", nil
          merge_sources()
        else
          catalog.status, catalog.message = "failed", perr
        end
        if on_done then on_done(ok, perr) end
        return
      end
      coroutine.yield(0.25)
    end
  end)
  return true
end

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
  if plugin._source == "provided" then return "provided" end
  if plugin._source == "builtin" then return "builtin" end
  if plugin._source == "installed" then
    if is_disabled(name) then return "disabled" end
    return "installed"
  end
  return "available"
end

function Manager.is_locked(name)
  local plugin = Manager.available[name]
  if not plugin then return false end
  return plugin._source == "builtin" or plugin._source == "provided"
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
