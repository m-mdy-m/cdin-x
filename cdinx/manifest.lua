-- Reads a package's manifest, whichever of the two forms it uses.
--
-- `package.lua` is the form: a separate file of pure data, read through the
-- sandbox in cdinx/schema.lua. The older form is the manifest table returned by
-- `init.lua` (or by a `manifest.lua` beside it), which is dofile()d — the
-- catalog has always done that, and a package with no `package.lua` keeps
-- working exactly as it did. That is also why such a package may not require
-- anything at the top of its init.lua: reading the manifest would run it. A
-- package with a `package.lua` is never executed to be listed, so its init.lua
-- is free to.
--
-- The result is the shape the rest of the kernel already uses: `type` rather
-- than `kind`, and `dependencies` as a sorted list rather than a range map.
-- Whatever the manifest said is kept alongside, so nothing has to be guessed
-- twice.
local Host   = require "cdinx.host"
local Schema = require "cdinx.schema"

local Manifest = {}

--- @class PackageMeta
--- @field name string
--- @field type string
--- @field dependencies string[]
--- @field entry string
--- @field category string|nil
--- @field _package_file string|nil set when the manifest was a package.lua
--- @field spec PackageSpec|nil the validated package.lua, when there was one

--- Reads `package.lua` from `dir`, or nil plus the reason.
--- @param dir string
--- @return PackageSpec|nil spec
--- @return string|nil err
function Manifest.read_package(dir)
  local file = dir .. "/package.lua"
  if not Host.fs.is_file(file) then return nil end
  return Schema.read(file)
end

--- The manifest of the package rooted at `plugin_path`.
--- @param plugin_path string
--- @return PackageMeta|nil meta
--- @return string|nil err
function Manifest.load(plugin_path)
  local spec, perr = Manifest.read_package(plugin_path)
  if spec then
    return {
      name = spec.name,
      version = spec.version,
      description = spec.description,
      type = spec.kind,
      dependencies = Schema.dependency_names(spec),
      entry = Schema.entry_of(spec),
      -- Carried through so a declared category reaches the panel. The catalog
      -- falls back to the domain directory for a package that states none, so a
      -- package that declares one keeps the grouping it has always had.
      category = spec.category,
      spec = spec,
      _package_file = plugin_path .. "/package.lua",
    }
  end
  if perr then return nil, perr end

  local manifest_file = plugin_path .. "/manifest.lua"
  if Host.fs.is_file(manifest_file) then
    local ok, value = pcall(dofile, manifest_file)
    if not ok then
      return nil, "manifest error: " .. tostring(value)
    end
    if type(value) ~= "table" then
      return nil, "manifest must return a table"
    end
    return value
  end

  local init_file = plugin_path .. "/init.lua"
  if Host.fs.is_file(init_file) then
    local ok, value = pcall(dofile, init_file)
    if not ok then
      return nil, "init.lua error: " .. tostring(value)
    end
    if type(value) ~= "table" then
      return nil, "init.lua must return a table"
    end
    if type(value.name) ~= "string" then
      return nil, "init.lua has no inline manifest fields (and no manifest.lua present)"
    end
    return value
  end

  return nil, "missing package.lua, manifest.lua or init.lua"
end

function Manifest.validate(m)
  local errors = {}

  -- A bundle decides what a build carries; no package decides that about
  -- itself. The field is gone from the tree, and a package that still sets it
  -- is reading an older document and expecting a guarantee it no longer gets.
  if m.essential ~= nil then
    errors[#errors + 1] = "essential is not a manifest field: name a bundle " ..
      "in bundles/<name>.lua instead"
  end

  if type(m.name) ~= "string" or m.name == "" then
    errors[#errors + 1] = "name is required"
  end
  if type(m.version) ~= "string" or m.version == "" then
    errors[#errors + 1] = "version is required"
  end
  if type(m.description) ~= "string" then
    errors[#errors + 1] = "description is required"
  end

  -- `category` groups a package in the panel and decides where a build puts it.
  -- The inline form has always carried it and is held to it; a package.lua may
  -- state it and falls back to the catalog's own grouping, which is the domain
  -- directory it sits in.
  if type(m.category) ~= "string" or m.category == "" then
    if m.spec then
      m.category = "unknown"
    else
      errors[#errors + 1] = "category is required"
    end
  end

  if m.type ~= nil and m.type ~= "plugin" and m.type ~= "theme" then
    errors[#errors + 1] = "type must be 'plugin' or 'theme'"
  end
  if m.dependencies ~= nil and type(m.dependencies) ~= "table" then
    errors[#errors + 1] = "dependencies must be a table"
  end

  return #errors == 0, errors
end

return Manifest