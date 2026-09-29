local Catalog = require "cdinx.manager.catalog"

local Deps = {}

-- A plugin the host already loaded counts as available: it is running, so
-- an integration that depends on it can load against it. The host strips
-- it from ctx.available, so it has to be recognised here explicitly or every
-- integration that declares `dependencies = { "vim", … }` would fail with
-- "dependency 'vim' is not installed" on a completely stock install.
local function is_provided(ctx, name)
  return ctx.provided ~= nil and ctx.provided[name] == true
end

function Deps.topological_order(ctx, names)
  local ordered, visiting, visited = {}, {}, {}

  local function visit(name)
    -- Already running in the host: nothing to order, nothing to load.
    if is_provided(ctx, name) then
      visited[name] = true
      return true
    end
    if visited[name] then return true end
    if visiting[name] then
      return false, "dependency cycle involving " .. name
    end

    local plugin = ctx.available[name]
    if not plugin then
      return false, "missing dependency: " .. name
    end

    visiting[name] = true
    for _, dep in ipairs(plugin.dependencies or {}) do
      if not is_provided(ctx, dep)
      and not Catalog.is_builtin(ctx, dep)
      and not Catalog.is_installed(ctx, dep) then
        return false, "dependency '" .. dep .. "' is not installed"
      end
      local ok, err = visit(dep)
      if not ok then return false, err end
    end
    visiting[name] = nil
    visited[name] = true
    ordered[#ordered + 1] = name
    return true
  end

  for _, name in ipairs(names) do
    local ok, err = visit(name)
    if not ok then return nil, err end
  end
  return ordered
end

-- Exported so Runtime.load_plugin can skip a host-provided plugin reached
-- by a name rather than through the load order.
Deps.is_provided = is_provided

return Deps
