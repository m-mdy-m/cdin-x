local Catalog = require "core.x.manager.catalog"

local Deps = {}

function Deps.topological_order(ctx, names)
  local ordered, visiting, visited = {}, {}, {}

  local function visit(name)
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
      if not Catalog.is_builtin(ctx, dep) and not Catalog.is_installed(ctx, dep) then
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

return Deps
