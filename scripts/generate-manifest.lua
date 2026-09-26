-- Generate X/manifest.lua from extension manifests and theme.lua files.
-- Plugins use manifest.lua; themes only need theme.lua (name field).
--
-- Each entry also carries `files`: every file that belongs to that
-- plugin/theme, as a path relative to the repo root (e.g.
-- "X/core/treeview/init.lua"). This lets an installer fetch a single
-- essential plugin file-by-file via raw.githubusercontent.com (or any
-- other raw-file host) WITHOUT cloning the repo and WITHOUT calling a
-- directory-listing API — the manifest itself is the file index.
--
-- The top-level `core_files` list does the same for the always-required
-- plugin-engine runtime in core/ (not a plugin, always needed).

local scan = dofile("scripts/_scan.lua")

local function q(s)
  return string.format("%q", tostring(s or ""))
end

local plugins = {}

-- Load plugins from manifest.lua files
for _, path in ipairs(scan.manifest_paths()) do
  local meta = scan.read_manifest(path)
  if meta and meta.name then
    local plugin_dir = scan.dirname(path)
    plugins[meta.name] = {
      category = meta.category or scan.category_from_manifest(path),
      type = meta.type or "plugin",
      version = meta.version or "0.0.0",
      description = meta.description or "",
      essential = meta.essential == true,
      files = scan.list_files_recursive(plugin_dir),
    }
  end
end

-- Load themes from theme.lua files
-- Themes don't have manifest.lua; they just have theme.lua with a name field.
local themes_dir = "X/themes"
if scan.exists(themes_dir) then
  for _, entry in ipairs(scan.list_dir(themes_dir) or {}) do
    if entry.type == "dir" and entry.name ~= ".git" then
      local theme_subdir = themes_dir .. "/" .. entry.name
      local theme_file = theme_subdir .. "/theme.lua"
      if scan.exists(theme_file) then
        local ok, theme_data = pcall(dofile, theme_file)
        if ok and type(theme_data) == "table" and theme_data.name then
          plugins[theme_data.name] = {
            category = "themes",
            type = "theme",
            version = "0.1.0",
            description = "Theme: " .. theme_data.name,
            essential = false,
            files = scan.list_files_recursive(theme_subdir),
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
  "-- Generated catalog index. Plugins use manifest.lua; themes use theme.lua.",
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
