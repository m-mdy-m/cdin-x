-- Regenerates X/manifest.lua, the generated catalog index.
--
-- The manager does not read this file: it scans the filesystem. It exists
-- so a consumer can see the whole catalog — and each entry's file list —
-- without walking the tree. What a build carries is decided by a bundle in
-- bundles/, never by a field in a manifest, so nothing here says so.
local scan = dofile("scripts/_scan.lua")

local function q(s)
  return string.format("%q", tostring(s or ""))
end

-- { "a", "b" } -- the dependency lists are written into the index so the
-- manager knows what an extension needs BEFORE it has downloaded it. Without
-- them, installing from the catalog fetches the one extension and none of
-- what it requires, and the result cannot load.
local function list(t)
  local out = {}
  for _, v in ipairs(t or {}) do out[#out + 1] = q(v) end
  return "{ " .. table.concat(out, ", ") .. " }"
end

local plugins = {}

for _, entry in ipairs(scan.plugin_entries()) do
  local meta = entry.meta
  if meta.name then
    plugins[meta.name] = {
      category = entry.category,
      type = meta.type or "plugin",
      version = meta.version or "0.0.0",
      description = meta.description or "",
      dependencies = meta.dependencies or {},
      optional_dependencies = meta.optional_dependencies or {},
      files = entry.single_file and { entry.path } or scan.list_files_recursive(entry.base),
    }
  end
end

-- A theme is a directory with theme.lua, so its file list is the directory
-- rather than the one file: the host may add assets beside the theme file.
for _, theme in ipairs(scan.theme_entries()) do
  plugins[theme.name] = {
    category = "themes",
    type = "theme",
    version = "0.1.0",
    description = "Theme: " .. theme.name,
    files = theme.base and scan.list_files_recursive(theme.base) or { theme.path },
  }
end

local names = {}
for name in pairs(plugins) do names[#names + 1] = name end
table.sort(names)

local lines = {
  "-- Generated catalog index - do not edit by hand; run",
  "-- `lua scripts/generate-manifest.lua` instead.",
  "--",
  "-- Every plugin carries its manifest inline: in init.lua for a",
  "-- directory plugin, in the returned table for a single-file one or a",
  "-- theme. There is no separate manifest.lua.",
  "--",
  "-- `files` on every entry lists that entry's files relative to the repo",
  "-- root, so callers can fetch them individually without cloning.",
  "return {",
  "  core_files = {",
}

-- The manager's own modules. Listed so a consumer can tell the difference
-- between "an extension" and "the thing that manages extensions".
for _, f in ipairs(scan.list_files_recursive("cdinx")) do
  lines[#lines + 1] = "    " .. q(f) .. ","
end

lines[#lines + 1] = "  },"
lines[#lines + 1] = "  plugins = {"

for _, name in ipairs(names) do
  local meta = plugins[name]
  lines[#lines + 1] = "    [" .. q(name) .. "] = {"
  lines[#lines + 1] = "      category = " .. q(meta.category) .. ","
  lines[#lines + 1] = "      type = " .. q(meta.type) .. ","
  lines[#lines + 1] = "      version = " .. q(meta.version) .. ","
  lines[#lines + 1] = "      description = " .. q(meta.description) .. ","
  if meta.dependencies and #meta.dependencies > 0 then
    lines[#lines + 1] = "      dependencies = " .. list(meta.dependencies) .. ","
  end
  if meta.optional_dependencies and #meta.optional_dependencies > 0 then
    lines[#lines + 1] = "      optional_dependencies = " .. list(meta.optional_dependencies) .. ","
  end
  lines[#lines + 1] = "      files = {"
  for _, f in ipairs(meta.files) do
    lines[#lines + 1] = "        " .. q(f) .. ","
  end
  lines[#lines + 1] = "      },"
  lines[#lines + 1] = "    },"
end

lines[#lines + 1] = "  },"
lines[#lines + 1] = "}"

-- X/manifest.lua has always been written with CRLF, and it stays that way.
-- What is new is that the endings are written deliberately: in text mode
-- the C runtime translates \n to \r\n on Windows and not on Linux, so the
-- same checkout produced two different files depending on who ran it. Binary
-- mode with an explicit separator means one script and one answer.
local fp, err = io.open("X/manifest.lua", "wb")
if not fp then error(err) end
fp:write(table.concat(lines, "\r\n"), "\r\n")
fp:close()

print(string.format("generated X/manifest.lua with %d extensions (+ %d manager files)",
  #names, #scan.list_files_recursive("cdinx")))
