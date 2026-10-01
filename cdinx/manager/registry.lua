-- Locating the extension registry — and nothing else.
local Util  = require "cdinx.manager.util"
local Fetch = require "cdinx.manager.fetch"

local Registry = {}

local syncer = nil

function Registry.set_syncer(fn)
  syncer = fn
end

-- Overridable through config.registry_dir, which the user config may set
-- from the environment via CDIN_X_REGISTRY.
function Registry.root(config)
  return Util.join(config.registry_dir, "X")
end

function Registry.ensure(config, ctx)
  local fs = require "core.fs"
  if fs.is_file(Util.join(Registry.root(config), "manifest.lua")) then
    return true
  end
  return false, "no extension catalog yet at " .. tostring(config.registry_dir)
    .. " (open the Extensions panel and press ctrl+r to download it)"
end

function Registry.refresh(config)
  local ok, err
  if syncer then
    ok, err = syncer(Registry.root(config), config.registry_raw_url)
  else
    ok, err = Fetch.sync(config.registry_dir, config.registry_raw_url)
  end
  if not ok then return false, tostring(err) end
  return true
end

Registry.registry_root = Registry.root

return Registry
