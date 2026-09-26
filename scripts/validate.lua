-- Minimal cdin-x structure validator.

local function exists(path)
  local f = io.open(path, "rb")
  if f then f:close(); return true end
  return false
end

local errors = {}
local root_files = { "README.md", "LICENSE", "core/init.lua", "core/manager.lua", "core/config.lua", "core/manifest.lua", "core/command.lua", "scripts/new-plugin.lua" }
for _, path in ipairs(root_files) do
  if not exists(path) then errors[#errors+1] = path .. " not found" end
end

-- Validate fonts directory
if not exists("fonts") then
  errors[#errors+1] = "fonts/ not found"
else
  local required_fonts = { "font.ttf", "monospace.ttf", "icons.ttf" }
  for _, f in ipairs(required_fonts) do
    if not exists("fonts/" .. f) then
      errors[#errors+1] = "fonts/" .. f .. " not found"
    end
  end
end

-- Validate core extensions (must have init.lua, manifest.lua, README.md)
local essentials = { "core", "autocomplete", "autoreload", "autoupdate", "projectsearch", "session", "trimwhitespace", "vim", "treeview", "tab", "window" }
for _, name in ipairs(essentials) do
  local base = "X/core/" .. name
  if not exists(base .. "/init.lua") then errors[#errors+1] = base .. "/init.lua not found" end
  if not exists(base .. "/manifest.lua") then errors[#errors+1] = base .. "/manifest.lua not found" end
  if not exists(base .. "/README.md") then errors[#errors+1] = base .. "/README.md not found" end
end

-- Validate themes: only theme.lua required (simplified structure)
-- Themes no longer need init.lua, manifest.lua, or README.md
-- Auto-discover theme directories
if exists("X/themes") then
  local handle = io.popen('ls -d X/themes/*/ 2>/dev/null')
  if handle then
    for dir in handle:lines() do
      local name = dir:match("[^/]+/$")
      if name and name ~= ".git" then
        local theme_path = dir .. "theme.lua"
        if not exists(theme_path) then
          errors[#errors+1] = theme_path .. " not found (themes need only theme.lua)"
        end
      end
    end
    handle:close()
  end
else
  errors[#errors+1] = "X/themes/ not found"
end

if #errors > 0 then
  print("cdin-x validation failed:")
  for _, err in ipairs(errors) do print("  - " .. err) end
  os.exit(1)
end

print("cdin-x structure valid")
