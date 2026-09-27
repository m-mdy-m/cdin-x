local scan = dofile("scripts/_scan.lua")

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

local essential_found = 0
for _, entry in ipairs(scan.plugin_entries()) do
  if entry.meta.essential == true then
    essential_found = essential_found + 1
    if entry.single_file then
      if not (type(entry.meta.init) == "function" or type(entry.meta.unload) == "function") then
        errors[#errors+1] = entry.path .. ": essential single-file plugin has no init/unload"
      end
    else
      if not exists(entry.base .. "/init.lua") then errors[#errors+1] = entry.base .. "/init.lua not found" end
      if not exists(entry.base .. "/README.md") then errors[#errors+1] = entry.base .. "/README.md not found" end
    end
  end
end
if essential_found == 0 then
  errors[#errors+1] = "no essential = true extensions found under X/ — expected at least one (e.g. core runtime plugins)"
end

local essential_theme_found = 0
if exists("X/themes") then
  for _, theme in ipairs(scan.theme_entries()) do
    if theme.data.essential == true then
      essential_theme_found = essential_theme_found + 1
    end
  end
else
  errors[#errors+1] = "X/themes/ not found"
end
if essential_theme_found == 0 then
  errors[#errors+1] = "no essential = true theme found under X/themes/ — expected exactly one built-in default"
elseif essential_theme_found > 1 then
  errors[#errors+1] = string.format(
    "%d themes are marked essential = true — expected exactly one built-in default theme",
    essential_theme_found)
end

if #errors > 0 then
  print("cdin-x validation failed:")
  for _, err in ipairs(errors) do print("  - " .. err) end
  os.exit(1)
end

print(string.format("cdin-x structure valid (%d essential extensions, %d essential theme)",
  essential_found, essential_theme_found))
