local fs       = require "core.fs"
local Manifest = require "core.x.manifest"
local Util     = require "core.x.manager.util"

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

local function scan_dir(dir, relpath, category, source, found)
  for _, entry in ipairs(fs.list(dir) or {}) do
    if entry.type == "dir" and entry.name ~= ".git" then
      local sub_dir = Util.join(dir, entry.name)
      local sub_rel = relpath == "" and entry.name or (relpath .. "/" .. entry.name)
      if is_plugin_dir(sub_dir) then
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

-- Scans all three roots and merges them into `ctx.available` / `ctx.sources`
-- by precedence: registry < installed < builtin (later entries win).
function Catalog.merge_sources(ctx, roots)
  local registry      = Catalog.scan_root(roots.registry, "registry")
  local local_plugins = Catalog.scan_root(roots.installed, "installed")
  local builtin       = Catalog.scan_root(roots.builtin, "builtin")

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

  ctx.available = all
  ctx.sources = source
  return all
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