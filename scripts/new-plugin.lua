local name = arg[1]
local category = arg[2] or "utils"
if not name or not name:match("^[%w%._%-]+$") then
  print("Usage: lua scripts/new-plugin.lua <name> [category]")
  print("  For themes: lua scripts/new-plugin.lua <name> theme")
  os.exit(1)
end
local base = "X/" .. category .. "/" .. name
local function mkdir(path)
  local sep = package.config:sub(1,1)
  if sep == "\\" then
    os.execute('mkdir "' .. path:gsub('/', '\\') .. '" >NUL 2>NUL')
  else
    os.execute('mkdir -p "' .. path:gsub('"', '\\"') .. '"')
  end
end
mkdir(base)
local files = {}
if category == "themes" then
  files[base .. "/theme.lua"] = string.format("-- %s theme\nreturn {\n  name = %q,\n  background = \"#1e1e2e\",\n}\n", name, name)
else
  files[base .. "/init.lua"] = string.format("local M = {}\nfunction M.init(core, config)\n  core.log('%s loaded')\nend\nfunction M.unload()\nend\nreturn M\n", name)
end
for path, content in pairs(files) do
  local f, err = io.open(path, "w")
  if not f then error(err) end
  f:write(content)
  f:close()
  print("Created: " .. path)
end
