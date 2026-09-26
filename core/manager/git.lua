-- Registry synchronization over git: cloning, pulling, and detecting a
-- sibling cdin-x checkout so a local dev setup never needs a network clone.
local core = require "core"
local fs   = require "core.fs"
local Git  = require "core.git.exec"
local Util = require "core.x.manager.util"

local RegistrySync = {}

local function git_in(dir, args)
  local exe = Git.exe_with_dir(dir)
  if not exe then
    return false, "git executable not found"
  end
  local a, b, c = os.execute(exe .. " " .. args)
  if Util.result_ok(a, b, c) then return true end
  return false, "git command failed"
end

local function registry_root(config)
  return Util.join(config.registry_dir, "X")
end

local function sibling_registry(config)
  local candidate = Util.join(EXEDIR, "..", "cdin-x")
  if fs.is_dir(Util.join(candidate, "X")) then
    return fs.abs(candidate)
  end
end

-- Ensures the registry is present (and optionally up to date), mutating
-- config.registry_dir / ctx flags in place when a sibling checkout is used
-- instead of a managed clone. Returns true on success.
function RegistrySync.ensure(config, ctx, force)
  if fs.is_dir(registry_root(config)) then
    if force and not ctx.registry_external then
      local ok, err = git_in(config.registry_dir, "pull --ff-only")
      if not ok then return false, err end
    end
    return true
  end

  local sibling = sibling_registry(config)
  if sibling then
    config.registry_dir = sibling
    ctx.registry_external = true
    return true
  end

  local parent = Util.parent_dir(config.registry_dir)
  fs.mkdir(parent)
  local ok, err = git_in(parent, "clone --depth 1 "
    .. Util.quote(config.registry_url) .. " "
    .. Util.quote(fs.basename(config.registry_dir)))
  if not ok then
    return false, "could not clone registry: " .. tostring(err)
  end

  return true
end

RegistrySync.registry_root = registry_root

return RegistrySync
