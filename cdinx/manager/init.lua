-- CDIN-X extension manager — public facade.
local Host = require "cdinx.host"
local fs   = Host.fs
local config   = require "cdinx.config"

local Util      = require "cdinx.manager.util"
local Registry  = require "cdinx.manager.registry"
local State     = require "cdinx.manager.state"
local Catalog   = require "cdinx.manager.catalog"
local Runtime   = require "cdinx.manager.runtime"
local Features  = require "cdinx.manager.features"
local Packages  = require "cdinx.packages"
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

-- Two roots, scanned for the same thing: `X/` holds what has not been moved
-- into `packages/` yet, and `packages/` holds what has. Both are searched, so a
-- tree can be half-moved -- which is exactly what it is while the move is in
-- progress -- and a package is found wherever it is.
local function builtin_roots()
  local roots = {}
  if config.bundle_dir then
    roots[#roots + 1] = Util.join(config.bundle_dir, "X")
    roots[#roots + 1] = Util.join(config.bundle_dir, "packages")
  end
  roots[#roots + 1] = Util.join(config.site_dir, "X")
  roots[#roots + 1] = Util.join(config.site_dir, "packages")
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
  for _, entry in ipairs(dir and Host.fs.list(dir) or {}) do
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

  -- The user's own choices, read once here so the config is known before any
  -- package asks what its features should be. Problems are logged rather than
  -- raised: a packages.lua with a typo in it must not stop the editor starting.
  -- `Packages` is the module-level upvalue from the top of this file. Re-requiring
  -- it here shadowed it with a second table, and the shadowed copy is the one that
  -- gets primed with this config while `apply_feature` -- which reads the upvalue --
  -- would have found empty. The two would then disagree about whether the user had
  -- said anything, which is a switch that works when written and not when read.
  local _, problems = Packages.load(config)
  for _, problem in ipairs(problems) do
    Host.core.log("cdin-x: %s", problem)
  end

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
    if Host.fs.is_dir(root) then builtin = builtin + 1 end
  end
  return {
    registry     = fs.is_file(Util.join(roots.registry, "manifest.lua")),
    installed    = Host.fs.is_dir(roots.installed),
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
  Host.core.add_thread(function()
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

--- The live context, for a caller that has to agree with the runtime about
--- something the runtime owns.
---
--- The panel needs this to read which features are *running*, which is not a
--- question the catalog can answer: `Features.active` consults the table the
--- runtime registers into, and there is exactly one of those. Handing it out is
--- better than having the panel build a context of its own, which would answer
--- about a session that is not running -- and would say so, confidently.
--- @return table
function Manager.context()
  return ctx
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
  if Host.fs.is_file(path) then return path end
  return nil
end

function Manager.open_readme(name)
  local plugin = Manager.available[name]
  if not plugin then return false, "unknown extension: " .. tostring(name) end

  local path = Manager.get_readme(name)
  if path then
    Host.core.root_view:open_doc(Host.core.open_doc(path))
    return true
  end

  if plugin._single_file then
    Host.core.log("%s: %s", plugin.name or name, plugin.description or "(no description)")
    return true
  end

  return false, "README not found"
end

-- Every package the user has switched off, whatever its source.
--
-- This replaces `get_essential_names`, which collected `plugin.essential == true` --
-- a field that no package may declare any more (schema, validate and check all
-- refuse it, and there is no `essential` left anywhere to set). So the function
-- returned an empty list to every caller, permanently and without complaint. It
-- was one of three places still reading a field the architecture deleted.
--
-- What the panel wants to draw as "always on" is a *build* package: something the
-- bundle shipped, which is not removable and not switchable, because the host
-- loads it. That is `is_locked`, and it is what the panel already uses.
function Manager.get_locked_names()
  merge_sources()
  local names = {}
  for name in pairs(Manager.available) do
    if Manager.is_locked(name) then names[#names + 1] = name end
  end
  table.sort(names)
  return names
end

-- ── features ───────────────────────────────────────────────────────────

--- Turns one feature of a loaded package on or off, now.
--
--- The panel's switch. The flag is already written to `packages.lua` by the time
--- this is called; this is the part that makes the next frame reflect it, rather
--- than the next start.
--
--- A feature is only reachable while its package is loaded, because the package's
--- `init` is what puts in place whatever the feature sits on. So turning one on
--- requires the package to be up, and turning one off requires it to still be up.
-- Both are checked rather than assumed: a switch that appears to work on an
--- unloaded package is worse than one that says it cannot.
--- @param name string
--- @param key string
--- @param on boolean
--- @return boolean ok
--- @return string|nil err
function Manager.apply_feature(name, key, on)
  -- Re-read the catalog. The panel calls this against a name it saw in the list, and
  -- between that draw and this keypress the list may have been rebuilt -- a rescan
  -- after an install, or a refresh from the panel itself. Reading a stale
  -- `Manager.available` would answer about a package that is no longer there.
  merge_sources()

  local plugin = Manager.available[name]
  if not plugin then return false, "unknown extension: " .. name end

  local spec = plugin.spec
  if not spec or not Features.has_any(spec) then
    return false, name .. " has no features"
  end

  -- Refuse an unknown key rather than reporting success. The panel can only offer a
  -- declared feature, so this is a caller error -- and a feature that "turned off"
  -- without existing is exactly the kind of thing that is never noticed.
  local declared = false
  for _, f in ipairs(Features.declared(spec)) do
    if f.key == key then declared = true break end
  end
  if not declared then
    local available = {}
    for _, f in ipairs(Features.declared(spec)) do available[#available + 1] = f.key end
    table.sort(available)
    return false, string.format("%s has no feature %q; it has %s", name, key,
      #available > 0 and table.concat(available, ", ") or "none")
  end

  if not ctx.installed[name] then
    if on then
      return false, name .. " is not loaded, so its features cannot be switched on"
    end
    -- Off, and it is already not running: the switch has nothing to undo and the
    -- answer is the one the user wanted.
    return true
  end

  if on then
    -- Enable needs the package's merged options, which is what `apply` would have
    -- passed. Recomputing here is deliberate rather than a shortcut: the options
    -- are `spec.options` plus the user's overrides, and Features owns that merge.
    local options = Features.options(spec, Packages.feature_overrides(name))
    local mod, err = Features.enable(ctx, name, key, options)
    if not mod then return false, err end
    return true
  end

  local ok, err = Features.disable(ctx, name, key)
  if not ok then return false, err end
  return true
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
