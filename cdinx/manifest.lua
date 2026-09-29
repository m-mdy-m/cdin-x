local fs = require "core.fs"

local Manifest = {}

function Manifest.load(plugin_path)
  local manifest_file = plugin_path .. "/manifest.lua"
  if fs.is_file(manifest_file) then
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
  if fs.is_file(init_file) then
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

  return nil, "missing manifest.lua or init.lua"
end

function Manifest.validate(m)
  local errors = {}

  if type(m.name) ~= "string" or m.name == "" then
    errors[#errors + 1] = "name is required"
  end
  if type(m.version) ~= "string" or m.version == "" then
    errors[#errors + 1] = "version is required"
  end
  if type(m.description) ~= "string" then
    errors[#errors + 1] = "description is required"
  end
  if type(m.category) ~= "string" or m.category == "" then
    errors[#errors + 1] = "category is required"
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
