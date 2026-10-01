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

-- "Can this name be loaded right now?" -- running in the host, shipped in the
-- build, or present in the user's extension store. A name that is only listed
-- in the catalog index (not downloaded) is NOT usable.
local function is_usable(ctx, name)
  return is_provided(ctx, name)
    or Catalog.is_builtin(ctx, name)
    or Catalog.is_installed(ctx, name)
end

-- Orders `names` so every plugin comes after the plugins it depends on.
--
-- Returns `ordered, skipped`.
--
-- A plugin that cannot be loaded (a dependency is not installed, or there is
-- a cycle) is *skipped*, never fatal: it lands in `skipped[name]` as
--   { reason = "<text>", missing = { "<dep>", ... } }
-- and so does everything that depends on it. One extension with unmet
-- dependencies must not take the manager -- and with it every other
-- extension -- down. That is exactly what used to happen: installing
-- vim-git by itself made `topological_order` return nil for the WHOLE set,
-- bootstrap failed, and nothing at all was loaded.
--
-- `optional_dependencies` only influence ordering: if an optional dependency
-- is part of this load it goes first, if it is absent nothing happens.
function Deps.topological_order(ctx, names)
  local ordered, skipped = {}, {}
  local visiting, visited = {}, {}

  local wanted = {}
  for _, name in ipairs(names) do wanted[name] = true end

  local function fail(name, reason, missing)
    skipped[name] = { reason = reason, missing = missing or {} }
    return false, reason
  end

  local function visit(name)
    -- Already running in the host: nothing to order, nothing to load.
    if is_provided(ctx, name) then
      visited[name] = true
      return true
    end
    if visited[name] then return true end
    if skipped[name] then return false, skipped[name].reason end
    if visiting[name] then
      return false, "dependency cycle involving " .. name
    end

    local plugin = ctx.available[name]
    if not plugin then
      return fail(name, "missing dependency: " .. name, { name })
    end

    visiting[name] = true

    -- Collect every problem instead of stopping at the first, so the user
    -- sees "needs git, menu, vim-menu" once, not three restarts' worth.
    local missing, blocked = {}, {}
    for _, dep in ipairs(plugin.dependencies or {}) do
      if not is_usable(ctx, dep) then
        missing[#missing + 1] = dep
      else
        local ok, err = visit(dep)
        if not ok then
          blocked[#blocked + 1] = string.format("%s (%s)", dep, tostring(err))
        end
      end
    end

    -- Soft dependencies: ordering only, and only when they are being loaded
    -- anyway. Failure here is ignored on purpose.
    for _, dep in ipairs(plugin.optional_dependencies or {}) do
      if wanted[dep] and is_usable(ctx, dep) and not visiting[dep] then
        visit(dep)
      end
    end

    visiting[name] = nil

    if #missing > 0 or #blocked > 0 then
      local parts = {}
      if #missing > 0 then
        parts[#parts + 1] = "missing dependencies: " .. table.concat(missing, ", ")
      end
      if #blocked > 0 then
        parts[#parts + 1] = "dependencies that could not load: " .. table.concat(blocked, ", ")
      end
      return fail(name, table.concat(parts, "; "), missing)
    end

    visited[name] = true
    ordered[#ordered + 1] = name
    return true
  end

  for _, name in ipairs(names) do
    visit(name)
  end
  return ordered, skipped
end

-- Exported so Runtime.load_plugin can skip a host-provided plugin reached
-- by a name rather than through the load order.
Deps.is_provided = is_provided
Deps.is_usable   = is_usable

return Deps
