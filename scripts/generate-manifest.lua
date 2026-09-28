local scan = dofile("scripts/_scan.lua")

local function q(s)
  return string.format("%q", tostring(s or ""))
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
      essential = meta.essential == true,
      files = entry.single_file and { entry.path } or scan.list_files_recursive(entry.base),
    }
  end
end

for _, theme in ipairs(scan.theme_entries()) do
  plugins[theme.name] = {
    category = "themes",
    type = "theme",
    version = "0.1.0",
    description = "Theme: " .. theme.name,
    essential = theme.data.essential == true,
    files = { theme.path },
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

for _, f in ipairs(scan.list_files_recursive("core")) do
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
  lines[#lines + 1] = "      essential = " .. tostring(meta.essential) .. ","
  lines[#lines + 1] = "      files = {"
  for _, f in ipairs(meta.files) do
    lines[#lines + 1] = "        " .. q(f) .. ","
  end
  lines[#lines + 1] = "      },"
  lines[#lines + 1] = "    },"
end

lines[#lines + 1] = "  },"
lines[#lines + 1] = "}"

local fp, err = io.open("X/manifest.lua", "w")
if not fp then error(err) end
fp:write(table.concat(lines, "\n"), "\n")
fp:close()

print(string.format("generated X/manifest.lua with %d extensions (+ %d core files)",
  #names, #scan.list_files_recursive("core")))
