-- Locating the extension registry — and nothing else.
--
-- The registry is a cache of the catalog: a list of extensions that can be
-- installed. cdin-x never fetches one here. Fetching is delegated to a
-- provider an extension registers, exactly like core.register_vcs_provider
-- does for status: see Registry.set_syncer. A registry that is not already
-- on disk is reported as missing rather than quietly created, so nothing
-- here needs the network.
--
-- This module does not look at the editor's installation layout, and does
-- not go looking for a checkout of this repository. Where the editor lives
-- is not cdin-x's business; the registry lives at config.registry_dir,
-- which the user can point anywhere.
local Util = require "cdinx.manager.util"

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

-- Returns true when a registry is already on disk. Never creates one and
-- never goes looking for a checkout of this repository.
function Registry.ensure(config, ctx)
  local fs = require "core.fs"
  if fs.is_dir(Registry.root(config)) then
    return true
  end
  return false, "no extension registry at " .. tostring(config.registry_dir)
    .. " (install the git extension to fetch one, or set config.registry_dir)"
end

-- A refresh is a fetch, so it needs a provider. Reported as unavailable
-- rather than quietly doing nothing when no extension offers one.
function Registry.refresh(config)
  if not syncer then
    return false, "refreshing the registry needs the git extension, which is not loaded"
  end

  local ok, err = syncer(Registry.root(config), config.registry_url)
  if not ok then return false, tostring(err) end
  return true
end

Registry.registry_root = Registry.root

return Registry
