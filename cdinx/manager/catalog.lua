local fs       = require "core.fs"
local Manifest = require "cdinx.manifest"
local Util     = require "cdinx.manager.util"

local Catalog = {}

-- A directory counts as a plugin root if it carries either manifest form.
local function is_plugin_dir(dir)
  return fs.is_file(dir .. "/manifest.lua") or fs.is_file(dir .. "/init.lua")
end

local function record(meta, name, path, relpath, category, single_file, source, found)
  meta.name = meta.name or name
  meta.category = meta.category or category
  meta.type = meta.type or "plugin"
  meta.dependencies = meta.dependencies or {}
  meta._path = path
  meta._relpath = relpath
  meta._single_file = single_file
  meta._source = source
  found[meta.name] = meta
end

local function is_theme_dir(category, dir)
  if category ~= "themes" then return false end
  if is_plugin_dir(dir) then return false end
  return fs.is_file(Util.join(dir, "theme.lua"))
end

local function record_theme(dir, name, relpath, source, found)
  local file = Util.join(dir, "theme.lua")
  local ok, data = pcall(dofile, file)
  if not ok or type(data) ~= "table" then
    core.log("cdin-x: skip %s: %s", relpath .. "/theme.lua", tostring(data))
    return
  end
  record(data, data.name or name, dir, relpath, "themes", false, source, found)
  found[data.name or name].type = "theme"
end

local function scan_dir(dir, relpath, category, source, found)
  for _, entry in ipairs(fs.list(dir) or {}) do
    if entry.type == "dir" and entry.name ~= ".git" then
      local sub_dir = Util.join(dir, entry.name)
      local sub_rel = relpath == "" and entry.name or (relpath .. "/" .. entry.name)
      if is_theme_dir(category, sub_dir) then
        record_theme(sub_dir, entry.name, sub_rel, source, found)
      elseif is_plugin_dir(sub_dir) then
        local meta, err = Manifest.load(sub_dir)
        if meta then
          record(meta, entry.name, sub_dir, sub_rel, category, false, source, found)
        else
          core.log("cdin-x: skip %s: %s", sub_rel, err)
        end
      else
        -- not a plugin: a grouping directory, keep descending
        scan_dir(sub_dir, sub_rel, category, source, found)
      end
    elseif entry.type == "file" and entry.name ~= "manifest.lua" then
      local name = entry.name:match("^(.+)%.lua$")
      if name then
        local file_path = Util.join(dir, entry.name)
        local ok, meta = pcall(dofile, file_path)
        if ok and type(meta) == "table" then
          record(meta, name, file_path, relpath .. "/" .. entry.name, category, true, source, found)
        else
          core.log("cdin-x: skip %s: %s", relpath .. "/" .. entry.name, tostring(meta))
        end
      end
    end
  end
end

function Catalog.scan_root(root, source_name)
  local found = {}
  if not root or not fs.is_dir(root) then
    return found
  end

  for _, category_entry in ipairs(fs.list(root) or {}) do
    if category_entry.type == "dir" and category_entry.name ~= ".git" then
      scan_dir(Util.join(root, category_entry.name), category_entry.name,
               category_entry.name, source_name, found)
    end
  end
  return found
end

-- ── the catalog index ─────────────────────────────────────────────────────
--
-- The registry is a sparse checkout holding X/manifest.lua and, once something
-- is installed, that one extension's files. scan_root() walks directories, so
-- on such a checkout it finds only what has already been materialised -- the
-- catalog would grow one entry per install, and search would answer "not
-- available" about everything else.
--
-- The manifest is the answer to "what exists". It lists every extension with
-- its category, version, description and file list, and it is one file rather
-- than the repository. Reading it is what lets the panel list and search the
-- whole catalog without the repository being downloaded.
--
-- Entries carry _listed rather than _materialised, so install knows to fetch
-- the files before copying them.

local function dirname_of(p)
  return (p:match("^(.*)/[^/]+$"))
end

local function relpath_of(entry)
  -- The manifest lists files as they sit in the repository
  -- ("X/themes/nord/theme.lua"). The extension store is keyed by the directory
  -- under X/ ("themes/nord"), and a single-file plugin is keyed by its name
  -- without the extension, because install_path_for appends ".lua" back.
  local first = entry.files and entry.files[1]
  if not first then return nil end

  local rel = first:match("^X/(.+)$")
  if not rel then return nil end

  local one_file = entry.files and #entry.files == 1

  -- A theme is a directory holding theme.lua, so its single file is a
  -- directory member, not the extension itself.
  if one_file and entry.type ~= "theme" and rel:match("%.lua$") then
    return rel:gsub("%.lua$", ""), true
  end

  local dir = dirname_of(rel)
  if dir then return dir, false end

  -- X/<name>.lua with nothing to strip: a single-file plugin at the root.
  if one_file then return rel:gsub("%.lua$", ""), true end
  return nil
end

local function manifest_index(root)
  if not root then return nil end
  local path = Util.join(root, "manifest.lua")
  if not fs.is_file(path) then return nil end

  local ok, data = pcall(dofile, path)
  if not ok or type(data) ~= "table" or type(data.plugins) ~= "table" then
    return nil
  end
  return data
end

-- Every extension the catalog offers, from the index alone.
-- `installed_root` (optional) is the user's extension store. An index entry
-- whose files are there IS installed, whatever its init.lua says when it is
-- dofile()d: presence on disk is the fact, and it must not depend on a
-- manifest scan succeeding.
function Catalog.scan_index(root, source_name, installed_root)
  local found = {}
  local index = manifest_index(root)
  if not index then return found end

  for name, entry in pairs(index.plugins) do
    if type(entry) == "table" then
      local rel, single_file = relpath_of(entry)
      local meta = {}
      for k, v in pairs(entry) do meta[k] = v end

      meta.name         = name
      meta.category     = meta.category or "core"
      meta.type         = meta.type or "plugin"
      meta.dependencies = meta.dependencies or {}
      meta._relpath     = rel
      meta._single_file = single_file or false
      meta._path        = rel and Util.join(root, rel) or nil
      meta._source      = source_name
      meta._listed      = true
      meta._materialised = meta._path ~= nil and fs.exists(meta._path)

      if installed_root and rel then
        local where = Util.join(installed_root, rel)
        if single_file then where = where .. ".lua" end
        if fs.exists(where) then
          meta._source       = "installed"
          meta._path         = where
          meta._materialised = true
        end
      end
      found[name] = meta
    end
  end
  return found
end

function Catalog.merge_sources(ctx, roots)
  -- The index first: it is the whole catalog, and it is one file. Whatever is
  -- materialised on disk then overrides it, because a directory that is really
  -- there is a better description of an extension than an index entry -- it
  -- carries whatever the extension actually declares, not what the index says
  -- it declares.
  local registry      = Catalog.scan_index(roots.registry, "registry", roots.installed)
  local local_plugins = Catalog.scan_root(roots.installed, "installed")

  for name, entry in pairs(Catalog.scan_root(roots.registry, "registry")) do
    registry[name] = entry
  end

  local all = {}
  local source = {}

  local function merge(found, name)
    for n, plugin in pairs(found) do
      all[n] = plugin
      -- An index entry found on disk in the user's store says "installed"
      -- itself; the root it was read from is only the fallback.
      source[n] = plugin._source or name
    end
  end

  merge(registry, "registry")
  merge(local_plugins, "installed")

  local builtins = roots.builtin or {}
  if type(builtins) == "string" then builtins = { builtins } end
  for _, root in ipairs(builtins) do
    merge(Catalog.scan_root(root, "builtin"), "builtin")
  end

  ctx.available = all
  ctx.sources = source
  return all
end

function Catalog.add_provided(ctx, provided)
  for name in pairs(provided or {}) do
    if ctx.available[name] then
      local existing = ctx.sources[name]
      if existing == "registry" or existing == "installed" or existing == "builtin" then
        -- already reported from a root that describes it properly
      else
        ctx.sources[name] = "builtin"
      end
    else
      ctx.available[name] = { name = name, category = "core", type = "plugin" }
      ctx.sources[name] = "provided"
    end
  end
  return ctx.available
end

function Catalog.is_builtin(ctx, name)
  return ctx.sources[name] == "builtin"
end

function Catalog.is_installed(ctx, name)
  return ctx.sources[name] == "installed"
end

function Catalog.search(ctx, query)
  query = (query or ""):lower()
  local results = {}
  for name, plugin in pairs(ctx.available) do
    if query == ""
      or name:lower():find(query, 1, true)
      or (plugin.description and plugin.description:lower():find(query, 1, true)) then
      results[name] = plugin
    end
  end
  return results
end

function Catalog.list_by_source(ctx, source_name)
  local result = {}
  for name, plugin in pairs(ctx.available) do
    if plugin._source == source_name then result[name] = plugin end
  end
  return result
end

return Catalog