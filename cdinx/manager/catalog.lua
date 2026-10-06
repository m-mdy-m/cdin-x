local Host     = require "cdinx.host"
local fs       = Host.fs
local Manifest = require "cdinx.manifest"
local Fetch    = require "cdinx.manager.fetch"
local Util     = require "cdinx.manager.util"

local Catalog = {}

-- The catalog roots a package may sit under, and where a registry's index may
-- be. Read rather than assumed, because a package is found under whichever root
-- has it, and a registry can hold either the newer index or the older one.
local CATALOG_ROOTS = { "packages", "X" }
local CATALOG_FILES = { "registry/generated/catalog.lua", "X/manifest.lua" }

-- The manifest forms a directory may carry, most preferred first: package.lua is
-- data read through a sandbox, the other two are dofile()d and have always been.
local MANIFEST_NAMES = { "package.lua", "manifest.lua", "init.lua" }

-- A directory counts as a plugin root if it carries any manifest form.
local function is_plugin_dir(dir)
  for _, name in ipairs(MANIFEST_NAMES) do
    if fs.is_file(dir .. "/" .. name) then return true end
  end
  return false
end

--- Puts one package into the map, refusing to overwrite a name this same walk
--- already claimed.
---
--- Two directories in one root declaring one name is not a precedence question
--- and must not be resolved as one: the catalog would silently load whichever it
--- happened to reach last, and the user would have no way to find out which. It
--- is a mistake in one of the two directories — usually a copy left behind by a
--- move — so it is reported by name with both paths, and the first claimant keeps
--- the slot so the rest of the scan is unaffected.
local function record(meta, name, path, relpath, category, single_file, source, found, clashes)
  meta.name = meta.name or name
  meta.category = meta.category or category
  meta.type = meta.type or "plugin"
  meta.dependencies = meta.dependencies or {}
  meta._path = path
  meta._relpath = relpath
  meta._single_file = single_file
  meta._source = source

  local held = found[meta.name]
  if held then
    clashes[#clashes + 1] = string.format(
      "%s is declared by two directories in %s: %s and %s",
      meta.name, source, tostring(held._relpath), tostring(relpath))
    return
  end
  found[meta.name] = meta
end

local function is_theme_dir(category, dir)
  if category ~= "themes" then return false end
  if is_plugin_dir(dir) then return false end
  return fs.is_file(Util.join(dir, "theme.lua"))
end

local function record_theme(dir, name, relpath, source, found, clashes)
  local file = Util.join(dir, "theme.lua")
  local ok, data = pcall(dofile, file)
  if not ok or type(data) ~= "table" then
    Host.core.log("cdin-x: skip %s: %s", relpath .. "/theme.lua", tostring(data))
    return
  end
  record(data, data.name or name, dir, relpath, "themes", false, source, found, clashes)
  local held = found[data.name or name]
  if held then held.type = "theme" end
end

local function scan_dir(dir, relpath, category, source, found, clashes)
  for _, entry in ipairs(Host.fs.list(dir) or {}) do
    if entry.type == "dir" and entry.name ~= ".git" then
      local sub_dir = Util.join(dir, entry.name)
      local sub_rel = relpath == "" and entry.name or (relpath .. "/" .. entry.name)
      if is_theme_dir(category, sub_dir) then
        record_theme(sub_dir, entry.name, sub_rel, source, found, clashes)
      elseif is_plugin_dir(sub_dir) then
        local meta, err = Manifest.load(sub_dir)
        if meta then
          record(meta, entry.name, sub_dir, sub_rel, category, false, source, found, clashes)
        else
          Host.core.log("cdin-x: skip %s: %s", sub_rel, err)
        end
      else
        -- not a plugin: a grouping directory, keep descending
        scan_dir(sub_dir, sub_rel, category, source, found, clashes)
      end
    elseif entry.type == "file" and entry.name ~= "manifest.lua" then
      local name = entry.name:match("^(.+)%.lua$")
      if name then
        local file_path = Util.join(dir, entry.name)
        local ok, meta = pcall(dofile, file_path)
        if ok and type(meta) == "table" then
          record(meta, name, file_path, relpath .. "/" .. entry.name, category, true,
            source, found, clashes)
        else
          Host.core.log("cdin-x: skip %s: %s", relpath .. "/" .. entry.name, tostring(meta))
        end
      end
    end
  end
end

--- Every package under one root, keyed by name.
---
--- The second return value names every name two directories in this root both
--- claimed. The caller decides what that is worth: a scan of a root it controls
--- treats it as an error, because two directories claiming one name is always a
--- mistake in one of them.
--- @param root string
--- @param source_name string
--- @return table<string, PackageMeta>
--- @return string[] clashes
function Catalog.scan_root(root, source_name)
  local found = {}
  if not root or not Host.fs.is_dir(root) then
    return found, {}
  end

  local clashes = {}
  for _, category_entry in ipairs(Host.fs.list(root) or {}) do
    if category_entry.type == "dir" and category_entry.name ~= ".git" then
      scan_dir(Util.join(root, category_entry.name), category_entry.name,
               category_entry.name, source_name, found, clashes)
    end
  end
  return found, clashes
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

--- Which root a manifest-listed file sits under, and the path below it.
--- @param path string
--- @return string|nil root
--- @return string|nil rest
local function split_root(path)
  for _, root in ipairs(CATALOG_ROOTS) do
    if path:sub(1, #root + 1) == root .. "/" then
      return root, path:sub(#root + 2)
    end
  end
  return nil, nil
end

local function relpath_of(entry)
  -- The manifest lists files as they sit in the repository
  -- ("packages/vcs/git/init.lua"). The extension store is keyed by the directory
  -- below the root ("vcs/git"), and a single-file plugin is keyed by its name
  -- without the extension, because install_path_for appends ".lua" back.
  local first = entry.files and entry.files[1]
  if not first then return nil end

  local _, rel = split_root(first)
  if not rel then return nil end

  local one_file = entry.files and #entry.files == 1

  -- A theme is a directory holding theme.lua, so its single file is a
  -- directory member, not the extension itself.
  if one_file and entry.type ~= "theme" and rel:match("%.lua$") then
    return rel:gsub("%.lua$", ""), true
  end

  local dir = dirname_of(rel)
  if dir then return dir, false end

  -- <root>/<name>.lua with nothing to strip: a single-file plugin at the root.
  if one_file then return rel:gsub("%.lua$", ""), true end
  return nil
end

-- The registry's index, read as text and never executed.
--
-- This is the file Fetch downloaded from a URL, so running it to find out what
-- it says would be running whatever the network handed back inside the editor.
-- Fetch.poll has already checked the shape once by the time a file is here; this
-- re-reads rather than trusting the staging copy, because a registry directory
-- can also be an older checkout the user has had for months.
--
-- `root` is the registry directory and the file is found by name, because a
-- registry can hold either the newer index or the older one.
local function manifest_index(root)
  if not root then return nil end
  for _, rel in ipairs(CATALOG_FILES) do
    local path = Util.join(root, rel)
    if Host.fs.is_file(path) then
      local ok, data = pcall(Fetch.read_catalog, path)
      if ok and type(data) == "table" then return data end
      Host.core.log("cdin-x: the registry index at %s is not a catalog; ignoring it", path)
      return nil
    end
  end
  return nil
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
      -- Which root the index listed this under, so a download and a store lookup
      -- both land in the same place the index says.
      local source_root
      if entry.files and entry.files[1] then
        source_root = split_root(entry.files[1])
      end
      local meta = {}
      for k, v in pairs(entry) do meta[k] = v end

      meta.name         = name
      meta.category     = meta.category or "core"
      meta.type         = meta.type or "plugin"
      meta.dependencies = meta.dependencies or {}
      meta._relpath     = rel
      meta._source_root = source_root
      meta._single_file = single_file or false
      meta._path        = rel and Util.join(root, rel) or nil
      meta._source      = source_name
      meta._listed      = true
      meta._materialised = meta._path ~= nil and Host.fs.exists(meta._path)

      if installed_root and rel then
        local where = Util.join(installed_root, rel)
        if single_file then where = where .. ".lua" end
        if Host.fs.exists(where) then
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
  -- The registry is a sparse checkout of this repository, so it may also hold
  -- materialised packages, under either catalog root.
  local local_plugins = Catalog.scan_root(roots.installed, "installed")

  for _, rel in ipairs(CATALOG_ROOTS) do
    for name, entry in pairs(Catalog.scan_root(Util.join(roots.registry, rel), "registry")) do
      registry[name] = entry
    end
  end

  local all = {}
  local source = {}

  -- Sources merged in precedence order, lowest first, so a later one wins. Two
  -- roots claiming one name is the design working; two *directories in one root*
  -- claiming one name is a mistake in the tree, and is reported rather than
  -- resolved by whichever the walk reached last.
  local clashes = {}

  local function merge(found, name, why)
    for n, plugin in pairs(found) do
      all[n] = plugin
      -- An index entry found on disk in the user's store says "installed"
      -- itself; the root it was read from is only the fallback.
      source[n] = plugin._source or name
    end
    for _, clash in ipairs(why or {}) do
      clashes[#clashes + 1] = clash
    end
  end

  merge(registry, "registry")
  merge(local_plugins, "installed")

  local builtins = roots.builtin or {}
  if type(builtins) == "string" then builtins = { builtins } end
  for _, root in ipairs(builtins) do
    local found, why = Catalog.scan_root(root, "builtin")
    merge(found, "builtin", why)
  end

  for _, clash in ipairs(clashes) do
    Host.core.error("cdin-x: %s", clash)
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