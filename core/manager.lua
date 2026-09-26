-- CDIN-X extension manager.
--
-- Runtime roots:
--   Built-in:   EXEDIR/data/X
--   Installed:  user data/extensions
--   Registry:   cached cdin-x repository /X
--
-- Built-in extensions are never copied and never removable.
-- Registry extensions are only catalog entries until installed.
-- Installed extensions are copied from the registry into the user store.

local core     = require "core"
local fs       = require "core.fs"
local config   = require "core.x.config"
local Manifest = require "core.x.manifest"

local Git = require "core.git.exec"

local Manager = {
  available = {},
  installed = {},
  sources = {},
  _registry_external = false,
  _bootstrapped = false,
  _state = { disabled = {} },
}

local function count(t)
  local n = 0
  for _ in pairs(t or {}) do n = n + 1 end
  return n
end

local function join(...)
  local values = {...}
  local out = values[1]
  for i = 2, #values do
    if out:sub(-1) ~= "/" and out:sub(-1) ~= "\\" then
      out = out .. PATHSEP
    end
    out = out .. values[i]
  end
  return out
end

local function quote(s)
  s = tostring(s)
  if PATHSEP == "\\" then
    return '"' .. s:gsub('"', '\\"') .. '"'
  end
  return "'" .. s:gsub("'", "'\\''") .. "'"
end

local function result_ok(a, b, c)
  if a == true then return true end
  if type(a) == "number" then return a == 0 end
  if type(c) == "number" then return c == 0 end
  return false
end

local function git_in(dir, args)
  local exe = Git.exe_with_dir(dir)
  if not exe then
    return false, "git executable not found"
  end
  local a, b, c = os.execute(exe .. " " .. args)
  if result_ok(a, b, c) then return true end
  return false, "git command failed"
end

local function user_extensions_root()
  return config.extension_dir
end

local function builtin_root()
  return join(EXEDIR, "data", "X")
end

local function registry_root()
  return join(config.registry_dir, "X")
end

local function parent_dir(path)
  return fs.dirname(path)
end

local function scan_root(root, source_name)
  local found = {}
  if not root or not fs.is_dir(root) then
    return found
  end

  -- Categories are intentionally open-ended. A repository contributor can add
  -- X/tools, X/ai, X/database, X/compiler, ... without changing the runtime.
  -- The manifest category is authoritative for presentation.
  for _, category_entry in ipairs(fs.list(root) or {}) do
    local category = category_entry.name
    if category_entry.type == "dir" and category ~= ".git" then
      local cat_dir = join(root, category)
      for _, entry in ipairs(fs.list(cat_dir) or {}) do
        if entry.type == "dir" then
          local plugin_dir = join(cat_dir, entry.name)
          local meta, err = Manifest.load(plugin_dir)
          if meta then
            meta.name = meta.name or entry.name
            meta.category = meta.category or category
            meta.type = meta.type or "plugin"
            meta.dependencies = meta.dependencies or {}
            meta._path = plugin_dir
            meta._source = source_name
            found[meta.name] = meta
          else
            core.log("cdin-x: skip %s/%s: %s", category, entry.name, err)
          end
        end
      end
    end
  end
  return found
end

local function merge_sources()
  local registry = scan_root(registry_root(), "registry")
  local local_plugins = scan_root(user_extensions_root(), "installed")
  local builtin = scan_root(builtin_root(), "builtin")

  local all = {}
  local source = {}

  for name, plugin in pairs(registry) do
    all[name] = plugin
    source[name] = "registry"
  end
  for name, plugin in pairs(local_plugins) do
    all[name] = plugin
    source[name] = "installed"
  end
  for name, plugin in pairs(builtin) do
    all[name] = plugin
    source[name] = "builtin"
  end

  Manager.available = all
  Manager.sources = source
  return all
end

local function load_state()
  local file = config.state_file
  if not fs.is_file(file) then
    Manager._state = { disabled = {} }
    return
  end

  local ok, state = pcall(dofile, file)
  if ok and type(state) == "table" then
    Manager._state = {
      disabled = type(state.disabled) == "table" and state.disabled or {},
    }
  else
    Manager._state = { disabled = {} }
  end
end

local function save_state()
  fs.mkdir(parent_dir(config.state_file))
  local fp, err = io.open(config.state_file, "w")
  if not fp then return false, err end

  fp:write("return {\n  disabled = {\n")
  local names = {}
  for name, disabled in pairs(Manager._state.disabled or {}) do
    if disabled then names[#names + 1] = name end
  end
  table.sort(names)
  for _, name in ipairs(names) do
    fp:write("    [", string.format("%q", name), "] = true,\n")
  end
  fp:write("  },\n}\n")
  fp:close()
  return true
end

local function sibling_registry()
  -- Development convenience: when cdin-x is cloned next to cdin, prefer
  -- that working tree instead of making a network request.
  local candidate = join(EXEDIR, "..", "cdin-x")
  if fs.is_dir(join(candidate, "X")) then
    return fs.abs(candidate)
  end
end

function Manager.ensure_registry(force)
  if fs.is_dir(registry_root()) then
    if force and not Manager._registry_external then
      local ok, err = git_in(config.registry_dir, "pull --ff-only")
      if not ok then return false, err end
    end
    merge_sources()
    return true
  end

  local sibling = sibling_registry()
  if sibling then
    config.registry_dir = sibling
    Manager._registry_external = true
    merge_sources()
    return true
  end

  local parent = parent_dir(config.registry_dir)
  fs.mkdir(parent)
  local ok, err = git_in(parent, "clone --depth 1 " .. quote(config.registry_url) .. " " .. quote(fs.basename(config.registry_dir)))
  if not ok then
    return false, "could not clone registry: " .. tostring(err)
  end

  merge_sources()
  return true
end

local function source_path(plugin)
  return plugin and plugin._path
end

local function is_disabled(name)
  return Manager._state.disabled[name] == true
end

local function is_runtime_plugin(plugin)
  return plugin and plugin.type ~= "theme"
end

local function is_builtin(name)
  return Manager.sources[name] == "builtin"
end

local function is_installed(name)
  return Manager.sources[name] == "installed"
end

local function installed_path(plugin)
  if not plugin then return nil end
  if plugin._source ~= "installed" then return nil end
  return plugin._path
end

local function active_path(name)
  local plugin = Manager.available[name]
  if not plugin then return nil end
  return source_path(plugin)
end

local function topological_order(names)
  local ordered, visiting, visited = {}, {}, {}

  local function visit(name)
    if visited[name] then return true end
    if visiting[name] then
      return false, "dependency cycle involving " .. name
    end

    local plugin = Manager.available[name]
    if not plugin then
      return false, "missing dependency: " .. name
    end

    visiting[name] = true
    for _, dep in ipairs(plugin.dependencies or {}) do
      if not is_builtin(dep) and not is_installed(dep) then
        return false, "dependency '" .. dep .. "' is not installed"
      end
      local ok, err = visit(dep)
      if not ok then return false, err end
    end
    visiting[name] = nil
    visited[name] = true
    ordered[#ordered + 1] = name
    return true
  end

  for _, name in ipairs(names) do
    local ok, err = visit(name)
    if not ok then return nil, err end
  end
  return ordered
end

function Manager.bootstrap()
  if Manager._bootstrapped then return true end
  load_state()
  merge_sources()

  -- Load all built-ins and all installed non-disabled extensions.
  local targets = {}
  for name, plugin in pairs(Manager.available) do
    if plugin._source == "builtin" then
      targets[#targets + 1] = name
    elseif plugin._source == "installed" and not is_disabled(name) then
      targets[#targets + 1] = name
    end
  end

  local ordered, err = topological_order(targets)
  if not ordered then
    core.log("cdin-x: load order error: %s", err)
    Manager._bootstrapped = false
    return false
  end

  for _, name in ipairs(ordered) do
    local plugin = Manager.available[name]
    if is_runtime_plugin(plugin) then
      local ok, load_err = Manager.load_plugin(name)
      if not ok then
        core.log("cdin-x: failed to load %s: %s", name, load_err)
      end
    end
  end

  Manager._bootstrapped = true
  return true
end

function Manager.scan()
  return merge_sources()
end

function Manager.load_plugin(name)
  local plugin = Manager.available[name]
  if not plugin then return false, "unknown extension: " .. name end
  if plugin.type == "theme" then return true end
  if Manager.installed[name] then return true end

  local init_path = join(plugin._path, "init.lua")
  if not fs.is_file(init_path) then
    return false, "missing init.lua: " .. init_path
  end

  for _, dep in ipairs(plugin.dependencies or {}) do
    if not Manager.installed[dep] then
      local ok, err = Manager.load_plugin(dep)
      if not ok then return false, err end
    end
  end

  local old_package_path = package.path
  package.path = plugin._path .. "/?.lua;" .. plugin._path .. "/?/init.lua;" .. old_package_path
  local ok, mod = pcall(dofile, init_path)
  package.path = old_package_path
  if not ok then return false, tostring(mod) end
  if type(mod) ~= "table" then
    return false, "init.lua must return a table"
  end

  if mod.init then
    local init_ok, init_err = pcall(mod.init, core, config)
    if not init_ok then
      return false, "init failed: " .. tostring(init_err)
    end
  end

  Manager.installed[name] = mod
  return true
end

function Manager.unload_plugin(name)
  local mod = Manager.installed[name]
  if not mod then return true end

  if mod.unload then
    local ok, err = pcall(mod.unload)
    if not ok then
      return false, "unload failed: " .. tostring(err)
    end
  end

  Manager.installed[name] = nil
  return true
end

function Manager.list()
  merge_sources()
  return Manager.available
end

function Manager.list_builtin()
  local result = {}
  for name, plugin in pairs(Manager.available) do
    if plugin._source == "builtin" then result[name] = plugin end
  end
  return result
end

function Manager.list_local()
  merge_sources()
  local result = {}
  for name, plugin in pairs(Manager.available) do
    if plugin._source == "installed" then result[name] = plugin end
  end
  return result
end

function Manager.list_loaded()
  return Manager.installed
end

function Manager.search(query)
  merge_sources()
  query = (query or ""):lower()
  local results = {}
  for name, plugin in pairs(Manager.available) do
    if query == ""
      or name:lower():find(query, 1, true)
      or (plugin.description and plugin.description:lower():find(query, 1, true)) then
      results[name] = plugin
    end
  end
  return results
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
  local path = join(plugin._path, "README.md")
  if fs.is_file(path) then return path end
  return nil
end

function Manager.open_readme(name)
  local path = Manager.get_readme(name)
  if not path then return false, "README not found" end
  core.root_view:open_doc(core.open_doc(path))
  return true
end

local function install_path_for(plugin)
  return join(config.extension_dir, plugin.category, plugin.name)
end

function Manager.install(name, stack)
  merge_sources()
  local plugin = Manager.available[name]
  if not plugin then
    local ok, err = Manager.ensure_registry(false)
    if not ok then return false, err end
    plugin = Manager.available[name]
  end
  if not plugin then return false, "extension not found in catalog: " .. name end

  if plugin._source == "builtin" then
    return true, "already built-in"
  end
  if plugin._source == "installed" then
    if plugin.type ~= "theme" and not Manager.installed[name] and not is_disabled(name) then
      Manager.load_plugin(name)
    end
    return true
  end

  stack = stack or {}
  if stack[name] then return false, "dependency cycle: " .. name end
  stack[name] = true
  for _, dep in ipairs(plugin.dependencies or {}) do
    local ok, err = Manager.install(dep, stack)
    if not ok then return false, "dependency " .. dep .. ": " .. tostring(err) end
  end
  stack[name] = nil

  local src = plugin._path
  local dst = install_path_for(plugin)
  fs.mkdir(fs.dirname(dst))

  if fs.exists(dst) then
    fs.rm(dst)
  end
  local ok, err = fs.copy(src, dst)
  if not ok then return false, err end

  Manager._state.disabled[name] = nil
  save_state()
  merge_sources()

  if plugin.type ~= "theme" then
    local loaded, load_err = Manager.load_plugin(name)
    if not loaded then return false, "installed but load failed: " .. tostring(load_err) end
  end

  return true
end

function Manager.install_local(path)
  path = fs.abs(path)
  if not fs.is_dir(path) then return false, "not a directory: " .. tostring(path) end

  local meta, err = Manifest.load(path)
  if not meta then return false, err end
  local ok, errors = Manifest.validate(meta)
  if not ok then return false, table.concat(errors, "; ") end
  meta.name = meta.name or fs.basename(path)

  for _, dep in ipairs(meta.dependencies or {}) do
    local installed = Manager.get(dep)
    if not installed or (installed._source ~= "builtin" and installed._source ~= "installed") then
      local ok_dep, dep_err = Manager.install(dep)
      if not ok_dep then
        return false, "dependency " .. dep .. ": " .. tostring(dep_err)
      end
    end
  end

  local dst = install_path_for(meta)
  fs.mkdir(fs.dirname(dst))
  if fs.exists(dst) then fs.rm(dst) end
  local copied, copy_err = fs.copy(path, dst)
  if not copied then return false, copy_err end

  merge_sources()
  if meta.type ~= "theme" then
    local loaded, load_err = Manager.load_plugin(meta.name)
    if not loaded then return false, "installed but load failed: " .. tostring(load_err) end
  end
  return true
end

function Manager.enable(name)
  local plugin = Manager.available[name]
  if not plugin then return false, "unknown extension: " .. name end
  if plugin._source == "builtin" then return true end
  if plugin._source ~= "installed" then return false, "extension is not installed" end

  Manager._state.disabled[name] = nil
  save_state()
  local ok, err = Manager.load_plugin(name)
  if not ok then return false, err end
  return true
end

function Manager.disable(name)
  local plugin = Manager.available[name]
  if not plugin then return false, "unknown extension: " .. name end
  if plugin._source == "builtin" or plugin.essential then
    return false, "essential extension cannot be disabled"
  end
  if plugin._source ~= "installed" then
    return false, "extension is not installed"
  end

  for other_name, other in pairs(Manager.available) do
    if other_name ~= name and other._source == "installed" and not is_disabled(other_name) then
      for _, dep in ipairs(other.dependencies or {}) do
        if dep == name then
          return false, "cannot disable " .. name .. ": required by " .. other_name
        end
      end
    end
  end

  local ok, err = Manager.unload_plugin(name)
  if not ok then return false, err end
  Manager._state.disabled[name] = true
  save_state()
  return true
end

function Manager.uninstall(name)
  local plugin = Manager.available[name]
  if not plugin then return false, "unknown extension: " .. name end
  if plugin._source == "builtin" or plugin.essential then
    return false, "essential extension cannot be removed: " .. name
  end
  if plugin._source ~= "installed" then
    return false, "extension is not installed: " .. name
  end

  -- Do not remove a dependency while another installed extension uses it.
  for other_name, other in pairs(Manager.available) do
    if other_name ~= name and other._source == "installed" then
      for _, dep in ipairs(other.dependencies or {}) do
        if dep == name then
          return false, "cannot remove " .. name .. ": required by " .. other_name
        end
      end
    end
  end

  local ok, err = Manager.disable(name)
  if not ok and Manager.installed[name] then return false, err end

  local path = installed_path(plugin)
  if path and fs.exists(path) then
    local rm_ok, rm_err = fs.rm(path)
    if not rm_ok then return false, rm_err end
  end
  Manager._state.disabled[name] = nil
  save_state()
  merge_sources()
  return true
end

function Manager.get_essential_names()
  local names = {}
  for _, name in ipairs(config.essential_plugins or {}) do
    names[#names + 1] = name
  end
  table.sort(names)
  return names
end

function Manager.refresh_registry()
  local ok, err = Manager.ensure_registry(true)
  if not ok then return false, err end
  merge_sources()
  return true
end

return Manager
