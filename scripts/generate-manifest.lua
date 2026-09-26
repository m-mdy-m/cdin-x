local scan = dofile("scripts/_scan.lua")

local function q(s)
  return string.format("%q", tostring(s or ""))
end

local plugins = {}

for _, found in ipairs(scan.discover_plugins("X")) do
  local meta = found.meta
  plugins[found.name] = {
    category = meta.category or found.category,
    type = meta.type or "plugin",
    version = meta.version or "0.0.0",
    description = meta.description or "",
    essential = meta.essential == true,
    files = scan.list_files_recursive(found.plugin_dir),
  }
end

local themes_dir = "X/themes"
if scan.exists(themes_dir) then
  for _, entry in ipairs(scan.list_dir(themes_dir) or {}) do
    if entry.type == "file" then
      local theme_name = entry.name:match("^(.+)%.lua$")
      if theme_name then
        local theme_file = themes_dir .. "/" .. entry.name
        local ok, theme_data = pcall(dofile, theme_file)
        if ok and type(theme_data) == "table" and theme_data.name then
          plugins[theme_data.name] = {
            category = "themes",
            type = "theme",
            version = "0.1.0",
            description = "Theme: " .. theme_data.name,
            essential = theme_data.essential == true,
            files = { theme_file },
          }
        end
      end
    end
  end
end

local names = {}
for name in pairs(plugins) do names[#names + 1] = name end
table.sort(names)

local lines = {
  "-- Generated catalog index. See core/manager/catalog.lua for the",
  "-- three on-disk plugin shapes this scans (folder + manifest.lua,",
  "-- folder + merged init.lua, or a single <name>.lua). Themes use theme.lua.",
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