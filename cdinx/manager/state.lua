local fs   = require "core.fs"
local Util = require "cdinx.manager.util"

local State = {}

function State.empty()
  return { disabled = {}, lock = {} }
end

function State.load(config)
  local file = config.state_file
  if not fs.is_file(file) then
    return State.empty()
  end

  local ok, state = pcall(dofile, file)
  if ok and type(state) == "table" then
    return {
      disabled = type(state.disabled) == "table" and state.disabled or {},
      lock     = type(state.lock) == "table" and state.lock or {},
    }
  end
  return State.empty()
end

function State.save(config, state)
  fs.mkdir(Util.parent_dir(config.state_file))
  local fp, err = io.open(config.state_file, "w")
  if not fp then return false, err end

  fp:write("return {\n  disabled = {\n")
  local names = {}
  for name, disabled in pairs(state.disabled or {}) do
    if disabled then names[#names + 1] = name end
  end
  table.sort(names)
  for _, name in ipairs(names) do
    fp:write("    [", string.format("%q", name), "] = true,\n")
  end
  fp:write("  },\n")

  fp:write("  lock = {\n")
  local lock_names = {}
  for name in pairs(state.lock or {}) do lock_names[#lock_names + 1] = name end
  table.sort(lock_names)
  for _, name in ipairs(lock_names) do
    local entry = state.lock[name]
    fp:write("    [", string.format("%q", name), "] = { version = ",
      string.format("%q", entry.version or ""), ", installed_at = ",
      string.format("%q", entry.installed_at or ""), " },\n")
  end
  fp:write("  },\n}\n")
  fp:close()
  return true
end

return State
