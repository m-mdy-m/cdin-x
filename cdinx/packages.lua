-- What the user wants, as data.
--
-- `<user_root>/packages.lua` is the one place a user says which packages are on
-- and which of their features they want. It replaces the panel's own state file as
-- the source of feature overrides.
--
-- Why a separate file, and why *this* file:
--
--   It is not the state file. `<data>/extensions.lua` is written by the editor,
--   from the panel, and describes what is *installed* -- disabled names, version
--   locks. Overwriting a file the user cannot read is how a user loses settings
--   they remember making. `packages.lua` is the opposite: readable, editable,
--   commented, and written by the user.
--
--   It is not `package.lua`. That file belongs to a package and describes what
--   that package *offers*; this one belongs to the user and describes what they
--   chose. Two files, two authors, two directions.
--
--   It is not the host's `init.lua`. That runs before plugins, cannot be written
--   by the editor without racing itself, and would put a data file into the one
--   place the host guarantees is code.
--
-- Before this file existed, feature overrides were dead: `State.load` read only
-- `disabled` and `lock`, and `State.save` wrote only those, so the table the
-- runtime consulted was always nil and every declared `default` won. That is the
-- shape of a bug that survives a long time -- nothing raises, every feature is
-- on, and the switch in the panel appears to do nothing.
--
-- This is read with the same sandbox the schema uses for `package.lua`, not
-- `dofile`. It lives beside `user/init.lua`, which *is* code and *is* dofile'd,
-- so the choice here is deliberate rather than an oversight: a file the editor may
-- one day write back should not be executable, and a user who wants logic can put
-- it in `init.lua` where it belongs.
local Host = require "cdinx.host"
local Schema = require "cdinx.schema"
local Util = require "cdinx.manager.util"

local Packages = {}

-- The whole vocabulary of this file. Anything else is a typo, and a typo in a
-- hand-edited settings file is worth naming rather than ignoring: the user reads
-- "search = false" and gets no effect, which looks like a bug in the editor.
local KNOWN_FIELDS = { packages = true, features = true }

local cache = nil
-- The config the file was read with, so the two accessors do not each have to be
-- handed one. Set by `load`, and it is the only place a config is needed.
local config_used = nil

--- An empty choice: every package on, every feature at its declared default.
--- @return table
function Packages.empty()
  return { packages = {}, features = {} }
end

--- Reads `<user_root>/packages.lua`, or an empty choice when there is none.
---
--- Never raises and never returns nil: a file the user is hand-editing will be
--- wrong sometimes, and the editor has to start anyway. Problems come back as
--- warnings so the panel can show them.
--- @param config table
--- @return table packages, string[] problems
function Packages.load(config)
  if cache then return cache.data, cache.problems end

  -- Fall back to the config module rather than to `config_used`. The boot path
  -- passes the config in; anything called later -- the panel, an audit -- does not,
  -- and `config_used` is nil at that point unless boot happened first. Requiring
  -- `cdinx.config` is the same table boot was handed: it is built once and cached
  -- in `package.loaded`. Without this the fallthrough is `file = nil`, the load
  -- returns "no file", caches it, and every later switch is silently inert -- which
  -- is the failure this whole file exists to avoid.
  config_used = config or config_used or require("cdinx.config")

  -- A path, checked for being a path and nothing more.
  --
  -- This used to insist the name ended in `packages.lua`. That was meant to catch a
  -- mis-set `config.packages_file` and it did something much worse: on Windows the
  -- temp directory is `%LOCALAPPDATA%\Temp`, so a harness path built from
  -- `os.getenv("TEMP")` does not match, the file was never opened, and the switch
  -- silently did nothing. A guard that turns a valid path into a silent no-op is
  -- worse than no guard -- and it hid behind "no problems", which reads as success.
  local file = config_used and config_used.packages_file
  if type(file) ~= "string" or file == "" then
    cache = { data = Packages.empty(), problems = {} }
    return cache.data, cache.problems
  end

  local fp = io.open(file, "rb")
  if not fp then
    cache = { data = Packages.empty(), problems = {} }
    return cache.data, cache.problems
  end
  local text = fp:read("*a")
  fp:close()

  -- The sandbox, but not `Schema.validate`: a package manifest is required to
  -- carry a name, a version, an author and a license, and this file has none of
  -- those and must not be made to invent them. What it *is* held to is the
  -- sandbox -- no require, no io, no os -- and that is the part a user is most
  -- likely to breach by accident when hand-editing.
  local value, err = Schema.sandboxed(text, "packages.lua")
  if type(value) ~= "table" then
    cache = { data = Packages.empty(), problems = { tostring(err or "not a table") } }
    return cache.data, cache.problems
  end

  local problems = {}
  for field in pairs(value) do
    if not KNOWN_FIELDS[field] then
      problems[#problems + 1] = string.format(
        "packages.lua: %q is not a field here; it will be ignored", tostring(field))
    end
  end

  local data = { packages = {}, features = {} }

  -- `packages = { git = true, search = false }` -- a package on or off.
  for name, on in pairs(value.packages or {}) do
    if type(name) ~= "string" or name == "" then
      problems[#problems + 1] = "packages.lua: a package name must be a non-empty string"
    elseif type(on) ~= "boolean" then
      problems[#problems + 1] = string.format(
        "packages.lua: packages[%q] wants true or false, got %s; treating it as on",
        name, type(on))
      data.packages[name] = true
    else
      data.packages[name] = on
    end
  end

  -- `features = { workspace = { tab = false } }` -- one table per package.
  for name, set in pairs(value.features or {}) do
    if type(name) ~= "string" or type(set) ~= "table" then
      problems[#problems + 1] =
        "packages.lua: features must be a package name mapped to a table of feature names"
    else
      local out = {}
      for key, on in pairs(set) do
        if type(on) ~= "boolean" then
          problems[#problems + 1] = string.format(
            "packages.lua: features.%s.%s wants true or false, got %s; leaving the default",
            name, tostring(key), type(on))
        else
          out[key] = on
        end
      end
      data.features[name] = out
    end
  end

  cache = { data = data, problems = problems }
  return data, problems
end

--- Checks what the user wrote against the catalog that exists.
---
--- `load` can only check a file against itself: that the values are booleans, that
--- the top-level fields are ones it knows. It cannot know that `gits` is not a
--- package, or that `workspace` has no feature called `windows`, because answering
--- either needs the catalog -- and the catalog is not built when this file is read.
---
--- So the two are compared here, after the catalog exists, and the answer is
--- reported rather than refused. A name that matches nothing is almost always a
--- package that was renamed or uninstalled between one session and the next, and
--- the user's line is then inert forever with no evidence. Saying so is the
--- difference between a typo the user can find and one they cannot.
---
--- Never changes what is applied. A package that is not installed cannot be
--- switched off, so the line is harmless either way; refusing the whole file over
--- one stale name would take the nineteen good lines down with it.
--- @param available table<string, table>  the merged catalog
--- @return string[] problems
function Packages.audit(available)
  local problems = {}
  if type(available) ~= "table" then return problems end

  -- An empty catalog means "we do not know", not "nothing exists", and the two
  -- produce identical reports: every line in the file flagged as unknown. That is
  -- what a missing root looks like from in here, so saying it would fill the log
  -- with invented mistakes on a build that is merely misconfigured.
  local known = 0
  for _ in pairs(available) do known = known + 1 end
  if known == 0 then return problems end

  local data = Packages.load()

  -- Names close to what was written, because "did you mean" is only useful if it
  -- is close. Sorted and capped: a list of every package is not help.
  local function suggest(name)
    local best, best_score = nil, 0
    for candidate in pairs(available) do
      if candidate ~= name then
        local score = 0
        -- A shared prefix is the common case (`gits`, `git`) and a shared
        -- substring catches `workspace` renamed to `workpace`.
        if candidate:sub(1, 1) == name:sub(1, 1) then
          local shared = 0
          while shared < #candidate and shared < #name
            and candidate:sub(shared + 1, shared + 1) == name:sub(shared + 1, shared + 1)
          do shared = shared + 1 end
          score = shared
        end
        if score > best_score then best, best_score = candidate, score end
      end
    end
    -- Two characters of agreement, or it is not a suggestion but a coincidence.
    if best and best_score >= 2 then return best end
    return nil
  end

  local names = {}
  for name in pairs(data.packages or {}) do names[#names + 1] = name end
  table.sort(names)
  for _, name in ipairs(names) do
    if available[name] == nil then
      local hint = suggest(name)
      problems[#problems + 1] = string.format("packages.lua: %q is not in the catalog%s",
        name, hint and (" -- did you mean " .. string.format("%q", hint) .. "?") or "")
    end
  end

  local feature_names = {}
  for name in pairs(data.features or {}) do feature_names[#feature_names + 1] = name end
  table.sort(feature_names)
  for _, name in ipairs(feature_names) do
    local plugin = available[name]
    if plugin == nil then
      problems[#problems + 1] = string.format(
        "packages.lua: features are set for %q, which is not in the catalog", name)
    else
      -- A feature key is checked here as well as in `Features.resolve`, because
      -- that one only runs for a package that is *loaded*. A package that is
      -- installed but switched off never reaches `resolve`, so a typo in the one
      -- file the user edits would be reported only while the package was on -- and
      -- then it would matter most.
      local declared = {}
      for key in pairs(plugin.spec and plugin.spec.features or {}) do
        declared[key] = true
      end
      local keys = {}
      for key in pairs(data.features[name] or {}) do keys[#keys + 1] = key end
      table.sort(keys)
      for _, key in ipairs(keys) do
        if not declared[key] then
          local known_keys = {}
          for k in pairs(declared) do known_keys[#known_keys + 1] = k end
          table.sort(known_keys)
          problems[#problems + 1] = string.format(
            "packages.lua: %s has no feature %q; it has %s", name, key,
            #known_keys > 0 and table.concat(known_keys, ", ")
              or "none, so the whole table has no effect")
        end
      end
    end
  end

  return problems
end

--- Forgets the file, so the next `load` reads it again.
---
--- The panel writes this file when the user changes a switch, and the only way to
--- see that is to read it again -- so this is the panel's refresh, not a test
--- convenience.
function Packages.invalidate()
  cache = nil
end

--- The feature overrides for one package, or nil when the user said nothing.
---
--- nil rather than an empty table, because "no opinion" and "an empty opinion"
--- are different: Features.resolve treats nil as "every declared default", and a
--- user who has opened the file and written nothing should get exactly that.
--- @param name string
--- @return table<string, boolean>|nil
function Packages.feature_overrides(name)
  local data = Packages.load()
  local for_package = data.features and data.features[name]
  if type(for_package) ~= "table" then return nil end
  return for_package
end

--- Whether the user has turned a package off.
---
--- Absent means on. That is the direction the whole file runs: everything is
--- available and a switch is an exception, so a user who writes nothing gets the
--- editor they had before the file existed.
--- @param name string
--- @return boolean
function Packages.is_enabled(name)
  local data = Packages.load()
  return data.packages[name] ~= false
end

--- Writes the file back, atomically enough for a settings file.
---
--- Comments are not preserved. A file the user edits by hand and the editor also
--- writes has to choose, and preserving comments means either a parser for Lua
--- source or a rewrite that loses the user's own words. Losing them on the first
--- panel click is bad; losing them silently is worse, so `write` is the only
--- caller and the panel is expected to say so.
--- @param config table
--- @return boolean ok
--- @return string|nil err
function Packages.write(config)
  local data = Packages.load(config)
  local file = config.packages_file
  if not file then return false, "no packages_file" end

  Host.fs.mkdir(Util.parent_dir(file))
  local fp, err = io.open(file, "w")
  if not fp then return false, err end

  fp:write("-- Written by cdin-x. Editable; safe to keep.\n")
  fp:write("--\n--   packages = { <name> = false }   turn a whole package off\n")
  fp:write("--   features = { <pkg> = { <key> = false } }   turn one feature off\n")
  fp:write("--\n-- Anything left out keeps the package's own default.\n")
  fp:write("return {\n")

  local names = {}
  for name in pairs(data.packages) do names[#names + 1] = name end
  table.sort(names)
  fp:write("  packages = {\n")
  for _, name in ipairs(names) do
    fp:write("    [", string.format("%q", name), "] = ",
      tostring(data.packages[name]), ",\n")
  end
  fp:write("  },\n")

  local pkgs = {}
  for name in pairs(data.features) do pkgs[#pkgs + 1] = name end
  table.sort(pkgs)
  fp:write("  features = {\n")
  for _, name in ipairs(pkgs) do
    fp:write("    [", string.format("%q", name), "] = {\n")
    local keys = {}
    for key in pairs(data.features[name]) do keys[#keys + 1] = key end
    table.sort(keys)
    for _, key in ipairs(keys) do
      fp:write("      [", string.format("%q", key), "] = ",
        tostring(data.features[name][key]), ",\n")
    end
    fp:write("    },\n")
  end
  fp:write("  },\n}\n")
  fp:close()

  Packages.invalidate()
  return true
end

return Packages