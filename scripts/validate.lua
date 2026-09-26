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
for _, path in ipairs(scan.manifest_paths()) do
  local meta = scan.read_manifest(path)
  if meta and meta.essential == true then
    essential_found = essential_found + 1
    local base = scan.dirname(path)
    if not exists(base .. "/init.lua") then errors[#errors+1] = base .. "/init.lua not found" end
    if not exists(base .. "/README.md") then errors[#errors+1] = base .. "/README.md not found" end
  end
end
if essential_found == 0 then
  errors[#errors+1] = "no essential = true extensions found under X/ — expected at least one (e.g. core runtime plugins)"
end

local essential_theme_found = 0
if exists("X/themes") then
  local handle = io.popen('ls -d X/themes/*/ 2>/dev/null')
  if handle then
    for dir in handle:lines() do
      local name = dir:match("[^/]+/$")
      if name and name ~= ".git" then
        local theme_path = dir .. "theme.lua"
        if not exists(theme_path) then
          errors[#errors+1] = theme_path .. " not found (themes need only theme.lua)"
        else
          local ok, theme_data = pcall(dofile, theme_path)
          if ok and type(theme_data) == "table" and theme_data.essential == true then
            essential_theme_found = essential_theme_found + 1
          end
        end
      end
    end
    handle:close()
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
