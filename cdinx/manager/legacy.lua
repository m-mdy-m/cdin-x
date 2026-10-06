-- Installed packages that predate the package layout.
--
-- An install in the user's store is a *copy* of a package from this repository, at
-- `<extension_dir>/<category>/<name>` -- which is the same path a fresh install
-- uses, because `install_path_for` still derives the category from the manifest.
-- So an old install is not a different layout. It is the same directory holding a
-- copy that predates `package.lua`.
--
-- What that costs is one thing: identity. A package with a `package.lua` claims
-- its name, so `require "git.api"` finds it. One without is reachable only by the
-- path-shaped spelling, `X.core.git.api`, which is what the legacy branch of the
-- loader serves. Everything the package does still works -- its own files require
-- each other by that spelling, and they are all from the same era.
--
-- So this module does not migrate anything. Rewriting a user's installed files to
-- the new spelling is a large, unreviewable edit to their home directory, done by
-- an editor at startup, to fix something that is not broken. The store is a copy:
-- the manager can put a correct one in place with one action, and that is the
-- remedy worth pointing at.
--
-- What it does instead is say so, once per session, and say which packages. A
-- silent difference between "installed before" and "installed now" is the kind of
-- thing that costs an afternoon.
local Host = require "cdinx.host"

local Legacy = {}

--- Packages in the store that answer only to their path-shaped name.
---
--- Not every package without a `package.lua` is old. A theme is a directory of
--- `<name>/theme.lua` and never had one; a syntax definition is a single file by
--- design. So the test is not "has no package.lua" but "is a runtime plugin that
--- would claim a name if it had one".
--- @param ctx table
--- @return { name: string, path: string, spelling: string }[]
function Legacy.find(ctx)
  local out = {}
  local available = ctx and ctx.available
  if type(available) ~= "table" then return out end

  local names = {}
  for name in pairs(available) do names[#names + 1] = name end
  table.sort(names)

  for _, name in ipairs(names) do
    local plugin = available[name]
    if plugin._source == "installed" and plugin.type ~= "theme"
       and not plugin._package_file and not plugin._single_file then
      out[#out + 1] = {
        name = name,
        path = plugin._path or "",
        -- What a user's own code would have to write to reach into it today.
        spelling = "X." .. tostring(plugin._relpath or plugin.name):gsub("/", ".")
                    .. ".<module>",
      }
    end
  end
  return out
end

--- Says what it found, once per session.
---
--- Once, because this is a fact about the store that does not change while the
--- editor runs, and a message on every frame would be a message nobody reads. Not
--- an error either: nothing is wrong, and nothing has to be done today.
--- @param ctx table
--- @return boolean  whether anything was reported
function Legacy.report(ctx)
  local found = Legacy.find(ctx)
  if #found == 0 then return false end
  if Legacy._reported then return false end
  Legacy._reported = true

  local names = {}
  for _, entry in ipairs(found) do names[#names + 1] = entry.name end

  Host.core.log(
    "cdin-x: %d installed extension(s) predate the package layout: %s",
    #found, table.concat(names, ", "))
  Host.core.log(
    "cdin-x: their modules are reachable only as X.<category>.<name>.<module>, "
    .. "not <name>.<module>. Everything they do still works. Reinstall one from "
    .. "the Extensions panel to get the new spelling -- no other action is needed.")

  return true
end

--- Forgets that anything was reported, so a test can ask twice.
function Legacy.reset()
  Legacy._reported = false
end

return Legacy