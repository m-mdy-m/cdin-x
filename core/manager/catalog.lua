-- Two on-disk formats are supported per <category>:
--   <category>/<name>/manifest.lua + init.lua   (old: one folder per plugin)
--   <category>/<name>.lua                        (new: one file per plugin;
--                                                  manifest fields + init/unload
--                                                  live in the same table)
local fs       = require "core.fs"
local Manifest = require "core.x.manifest"
local Util     = require "core.x.manager.util"

local Catalog = {}

function Catalog.scan_root(root, source_name)
  local found = {}
  if not root or not fs.is_dir(root) then
    return found
  end

  for _, category_entry in ipairs(fs.list(root) or {}) do
    local category = category_entry.name
    if category_entry.type == "dir" and category ~= ".git" then
      local cat_dir = Util.join(root, category)
      for _, entry in ipairs(fs.list(cat_dir) or {}) do
        if entry.type == "dir" then
          -- old format: <category>/<name>/manifest.lua + init.lua
          local plugin_dir = Util.join(cat_dir, entry.name)
          local meta, err = Manifest.load(plugin_dir)
          if meta then
            meta.name = meta.name or entry.name
            meta.category = meta.category or category
            meta.type = meta.type or "plugin"
            meta.dependencies = meta.dependencies or {}
            meta._path = plugin_dir
            meta._single_file = false
            meta._source = source_name
            found[meta.name] = meta
          else
            core.log("cdin-x: skip %s/%s: %s", category, entry.name, err)
          end
        elseif entry.name ~= "manifest.lua" then
          local name = entry.name:match("^(.+)%.lua$")
          if name then
            -- new format: <category>/<name>.lua — manifest fields plus
            -- init/unload all live in the one returned table.
            local file_path = Util.join(cat_dir, entry.name)
            local ok, meta = pcall(dofile, file_path)
            if ok and type(meta) == "table" then
              meta.name = meta.name or name
              meta.category = meta.category or category
              meta.type = meta.type or "plugin"
              meta.dependencies = meta.dependencies or {}
              meta._path = file_path
              meta._single_file = true
              meta._source = source_name
              found[meta.name] = meta
            else
              core.log("cdin-x: skip %s/%s: %s", category, entry.name, tostring(meta))
            end
          end
        end
      end
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