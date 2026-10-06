-- Locating the extension registry — and nothing else.
local Host  = require "cdinx.host"
local Util  = require "cdinx.manager.util"
local Fetch = require "cdinx.manager.fetch"

local Registry = {}

local syncer = nil

function Registry.set_syncer(fn)
  syncer = fn
end

-- The candidates Fetch may have written, in the order it prefers them. A list
-- rather than one path so a registry fetched before the move keeps working.
local CATALOG_FILES = { "registry/generated/catalog.lua", "X/manifest.lua" }

-- Overridable through config.registry_dir, which the user config may set
-- from the environment via CDIN_X_REGISTRY.
--
-- The registry directory itself, not a subdirectory of it: it is a sparse
-- checkout of this repository, so it holds whichever catalog root the tree
-- happens to use.
function Registry.root(config)
  return config.registry_dir
end

--- The catalog file that is actually there, or nil.
--- @param config table
--- @return string|nil path
--- @return string|nil relative  what to ask the remote for
function Registry.catalog_path(config)
  local dir = Registry.root(config)
  for _, rel in ipairs(CATALOG_FILES) do
    local path = Util.join(dir, rel)
    if Host.fs.is_file(path) then return path, rel end
  end
  return nil
end

function Registry.ensure(config, ctx)
  if Registry.catalog_path(config) then return true end
  return false, "no extension catalog yet at " .. tostring(config.registry_dir)
    .. " (open the Extensions panel and press ctrl+r to download it)"
end

function Registry.refresh(config)
  local ok, err
  if syncer then
    -- A registered syncer (git) is handed the file it must refresh, not the
    -- directory: the registry is a sparse checkout of one tree and the syncer
    -- knows which path in it it owns.
    local path, rel = Registry.catalog_path(config)
    ok, err = syncer(Registry.root(config), config.registry_raw_url, path, rel)
  else
    ok, err = Fetch.sync(config.registry_dir, config.registry_raw_url)
  end
  if not ok then return false, tostring(err) end
  return true
end

Registry.registry_root = Registry.root

return Registry
