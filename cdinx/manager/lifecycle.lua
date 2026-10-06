local Host = require "cdinx.host"
local fs   = Host.fs
local Manifest = require "cdinx.manifest"
local Util     = require "cdinx.manager.util"
local Catalog  = require "cdinx.manager.catalog"
local Runtime  = require "cdinx.manager.runtime"
local Fetch    = require "cdinx.manager.fetch"

local Lifecycle = {}

--- Whether the running host satisfies what a package asked for.
---
--- `min_cdin_version` is declared by every package and validated by the schema, and
--- until now nothing compared it. That is the worst shape for a compatibility
--- promise: it is written down, it is checked for shape, and it means nothing, so a
--- package written against a newer host installs cleanly and then fails somewhere
--- less obvious.
---
--- The comparison is here rather than at load because that is where the answer is
--- actionable. At load the only available answer is "skip it", which produces an
--- editor missing something with nothing in the log; at install the user is already
--- looking at a decision and can be told why before making it.
---
--- Deliberately a *warning*, not a refusal. A package that declares a minimum it
--- cannot meet has not been shown to be broken -- a patch release may well work --
--- and refusing to install it would make cdin-x the thing deciding what a version
--- number means. It says so and lets the user choose.
---
--- When the host does not report a version at all, this returns true. "Unknown" is
--- not evidence of incompatibility, and refusing everything against a host that
--- simply does not say would be the loudest possible wrong answer.
--- @param plugin table
--- @return boolean satisfied
--- @return string|nil reason
local function compatible_with_host(plugin)
  local want = plugin.min_cdin_version
  if not want or want == "" then return true end

  local have = Host.version
  if not have or have == "" then
    -- Logged rather than silent: a user on a host that does not report its version
    -- has just had a compatibility promise they cannot rely on, and that is worth
    -- one line.
    return true, string.format(
      "cdin-x: %s asks for cdin %s but this editor does not report its version; "
      .. "installing anyway", tostring(plugin.name), want)
  end

  -- Compare the release triple only. A pre-release suffix ("0.6.0-rc1") is not
  -- something either side can order meaningfully here, and treating it as less than
  -- the release would refuse a package against a build of the same version.
  local function triple(v)
    return tonumber(v:match("^(%d+)")), tonumber(v:match("^%d+%.(%d+)")), tonumber(v:match("^%d+%.%d+%.(%d+)"))
  end
  local wm, wn, wp = triple(want)
  local hm, hn, hp = triple(have)
  if not (wm and wn and wp and hm and hn and hp) then
    -- An unparseable version is not a reason to refuse; say nothing and let it load.
    return true
  end

  if hm > wm then return true end
  if hm < wm then return false end
  if hn > wn then return true end
  if hn < wn then return false end
  return hp >= wp
end

-- Where a plugin is copied inside the user's extension store.
local function install_path_for(config, plugin)
  local rel = plugin._relpath
  if not rel or rel == "" then
    rel = (plugin.category or "unknown") .. "/" .. (plugin.name or "unknown")
  end
  local base = Util.join(config.extension_dir, rel)
  if plugin._single_file then
    return base .. ".lua"
  end
  return base
end

local function is_disabled(ctx, name)
  return ctx.state.disabled[name] == true
end

local function place(src, dst)
  Fetch.mkdir_p(Host.fs.dirname(dst))
  if Host.fs.exists(dst) then Host.fs.rm(dst) end

  local moved = Host.fs.move and Host.fs.move(src, dst)
  if not moved or not Host.fs.exists(dst) then
    local ok, err = Host.fs.copy(src, dst)
    if not ok then return false, err or ("could not copy to " .. dst) end
  end
  if not Host.fs.exists(dst) then
    return false, "nothing was written to " .. dst
  end
  return true
end

local function fetch_entry(config, plugin)
  local rel = plugin._relpath
  if not rel then
    return false, "the catalog index has no file list for " .. tostring(plugin.name)
  end
  local staged, err = Fetch.download(config.registry_dir, config.registry_raw_url,
    plugin.name, plugin.files)
  if not staged then return false, err end

  -- The staging directory keeps each package under the root it was listed at,
  -- because that is how Fetch.download wrote it; the store is keyed by the path
  -- below the root.
  local root = plugin._source_root or "X"
  local src = Util.join(staged, root, (rel:gsub("/", Host.sep)))
  if plugin._single_file then src = src .. ".lua" end
  if not Host.fs.exists(src) then
    Fetch.discard(staged)
    return false, "the download of " .. tostring(plugin.name) .. " was incomplete"
  end
  return src, staged
end

local function declared_deps(plugin, src)
  if plugin.type == "theme" or not src then return {} end
  local meta
  if plugin._single_file then
    local ok, m = pcall(dofile, src)
    if ok and type(m) == "table" then meta = m end
  else
    meta = Manifest.load(src)
  end
  return type(meta) == "table" and meta.dependencies or {}
end

-- Whether the catalog entry already listed `dep` (and so it was handled).
local function listed_dep(plugin, dep)
  for _, d in ipairs(plugin.dependencies or {}) do
    if d == dep then return true end
  end
  return false
end

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
  if plugin._source == "provided" then
    return true, "provided by the editor"
  end

  -- Said before the dependency walk, so a package that cannot work here does not
  -- pull a chain of dependencies onto disk on the way to failing.
  local satisfied, why = compatible_with_host(plugin)
  if not satisfied then
    return false, string.format(
      "%s needs cdin %s or newer; this is %s", name, plugin.min_cdin_version,
      tostring(Host.version))
  end
  if why then Host.core.log("cdin-x: %s", why) end

  stack = stack or {}
  if stack[name] then return false, "dependency cycle: " .. name end

  stack[name] = true
  for _, dep in ipairs(plugin.dependencies or {}) do
    local dep_plugin = ctx.available[dep]
    local needs_fetch = dep_plugin
      and dep_plugin._source ~= "builtin"
      and dep_plugin._source ~= "provided"
      and dep_plugin._source ~= "installed"
    local ok, err = Lifecycle.install(ctx, config, dep, ensure_registry, save_state, stack)
    if not ok then
      stack[name] = nil
      return false, "dependency " .. dep .. ": " .. tostring(err)
    end
    if needs_fetch then
      Host.core.log("cdin-x: installed %s (required by %s)", dep, name)
    end
  end
  stack[name] = nil

  if plugin._source == "installed" then
    if plugin.type ~= "theme" and not ctx.installed[name] and not is_disabled(ctx, name) then
      -- Dependencies may have just been put on disk; make the manager see
      -- them before it tries to load against them.
      if ctx.rescan then ctx.rescan() end
      Runtime.load_plugin(ctx, name)
    end
    return true
  end

  local src, staged = plugin._path, nil
  if plugin._listed and not plugin._materialised then
    src, staged = fetch_entry(config, plugin)
    if not src then return false, staged end
  end

  stack[name] = true
  for _, dep in ipairs(declared_deps(plugin, src)) do
    -- A plugin the host already runs (vim, say) needs nothing from us.
    local host_has = ctx.provided ~= nil and ctx.provided[dep] == true
    if not host_has and not listed_dep(plugin, dep) then
      local ok, err = Lifecycle.install(ctx, config, dep, ensure_registry, save_state, stack)
      if not ok then
        stack[name] = nil
        Fetch.discard(staged)
        return false, "dependency " .. dep .. ": " .. tostring(err)
      end
      Host.core.log("cdin-x: installed %s (required by %s)", dep, name)
    end
  end
  stack[name] = nil

  local dst = install_path_for(config, plugin)
  local ok, err = place(src, dst)
  Fetch.discard(staged)
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
  path = Host.fs.abs(path)

  local meta, err, single_file
  if Host.fs.is_dir(path) then
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

  -- The same check as `install`, and for the same reason: this is the path that
  -- puts a package onto disk without going through the catalog, so a package that
  -- cannot work on this host would otherwise arrive here and nowhere else.
  local satisfied, why = compatible_with_host(meta)
  if not satisfied then return false, why end
  if why then Host.core.log("cdin-x: %s", why) end

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
  Fetch.mkdir_p(Host.fs.dirname(dst))
  if Host.fs.exists(dst) then Host.fs.rm(dst) end
  local copied, copy_err = Host.fs.copy(path, dst)
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
  local index = Catalog.scan_index(registry_root, "registry")
  for _, n in ipairs(names) do
    local installed_plugin = ctx.available[n]
    if not installed_plugin or installed_plugin._source ~= "installed" then
      errors[#errors + 1] = n .. ": not installed"
    else
      local locked = ctx.state.lock[n]
      local registry_plugin = index[n]
      if not registry_plugin then
        -- Not in the registry (e.g. installed via install_local) — nothing to compare against.
      elseif locked and locked.version == (registry_plugin.version or "") then
        -- Already at the latest known version; nothing to do.
      else
        -- Download first: if it fails, the installed copy is untouched.
        local src, staged = fetch_entry(config, registry_plugin)
        if not src then
          errors[#errors + 1] = n .. ": " .. tostring(staged)
        else
        local dst = install_path_for(config, installed_plugin)
        local was_loaded = ctx.installed[n] ~= nil
        if was_loaded then Runtime.unload_plugin(ctx, n) end
        local copied, copy_err = place(src, dst)
        Fetch.discard(staged)
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
  end

  return #errors == 0, { updated = updated, errors = errors }
end

function Lifecycle.clean(ctx, user_extensions_root, registry_root, dry_run)
  local depended_on = {}
  for _, plugin in pairs(ctx.available) do
    if plugin._source == "installed" then
      for _, dep in ipairs(plugin.dependencies or {}) do
        depended_on[dep] = true
      end
      for _, dep in ipairs(plugin.optional_dependencies or {}) do
        depended_on[dep] = true
      end
    end
  end

  local on_disk = Catalog.scan_root(user_extensions_root, "installed")

  local index = Catalog.scan_index(registry_root, "registry")
  local have_index = next(index) ~= nil

  local orphaned = {}
  for name, plugin in pairs(on_disk) do
    -- `not plugin.essential` was always true, since no package may declare that
    -- field any more, so this test never actually protected anything. What it was
    -- reaching for is "something the build brought", which is `plugin._source ==
    -- "builtin"` -- and the second term already covers it: a build package is in
    -- the index, so it is not orphaned regardless. The explicit test is kept so
    -- the reason is visible rather than inferred.
    local from_build = plugin._source == "builtin"
    if have_index and not from_build and not depended_on[name] then
      local still_in_registry = index[name] ~= nil
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
    local ok, err = Host.fs.rm(plugin._path)
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
  -- "part of the editor" rather than "essential": the field is gone and the
  -- panel already words it that way, so the message and the test now agree.
  if plugin._source == "builtin" then
    return false, plugin.name .. " is part of the editor and cannot be disabled"
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
  if plugin._source == "builtin" then
    return false, plugin.name .. " is part of the editor and cannot be removed"
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
  if path and Host.fs.exists(path) then
    local rm_ok, rm_err = Host.fs.rm(path)
    if not rm_ok then return false, rm_err end
  end
  ctx.state.disabled[name] = nil
  ctx.state.lock[name] = nil
  save_state()
  return true
end

Lifecycle.install_path_for = install_path_for

return Lifecycle
