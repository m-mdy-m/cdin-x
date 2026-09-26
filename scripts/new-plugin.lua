-- Create a minimal cdin-x extension or theme.
-- Usage: lua scripts/new-plugin.lua <name> [category]
--
-- For themes: lua scripts/new-plugin.lua <name> theme
-- For plugins: lua scripts/new-plugin.lua <name> [category]

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
  -- Themes are simplified: just theme.lua
  files[base .. "/theme.lua"] = string.format([[-- %s theme
return {
  name = %q,
  background = "#1e1e2e", background2 = "#181825", background3 = "#313244",
  text = "#cdd6f4", caret = "#f5e0dc",
  accent = "#cba6f7",
  dim = "#6c7086", divider = "#313244", selection = "#45475a",
  line_number = "#585b70", line_number2 = "#cba6f7",
  line_highlight = "#232336", scrollbar = "#181825", scrollbar2 = "#585b70",
  search_highlight = { 249, 226, 175, 90 },
  titlebar_text = "#a6adc8", titlebar_text_focus = "#cdd6f4",
  titlebar_button_hover = "#313244", titlebar_close_hover = "#f38ba8",
  vim_pill_fg = "#1e1e2e", vim_normal_bg = "#45475a",
  vim_insert_bg = "#89b4fa", vim_visual_bg = "#f5c2e7",
  vim_replace_bg = "#f38ba8", vim_command_bg = "#a6e3a1",
  git_modified = "#f9e2af", git_added = "#a6e3a1", git_deleted = "#f38ba8",
  git_conflict = "#fab387", git_untracked = "#6c7086", git_renamed = "#cba6f7",
  syntax = {
    normal = "#cdd6f4", symbol = "#bac2de", comment = "#6c7086",
    keyword = "#cba6f7", keyword2 = "#f5c2e7", number = "#fab387",
    literal = "#f5e0dc", string = "#a6e3a1", operator = "#89dceb",
    ["function"] = "#89b4fa",
  },
}
]], name, name)
else
  -- Plugins use init.lua, manifest.lua, README.md.
  -- init.lua loads its own manifest.lua for descriptive metadata
  -- (name, version, essential, tags, ...) so nothing is duplicated
  -- between the two files — only runtime config/init/unload live here.
  files[base .. "/init.lua"] = string.format([[local function plugin_dir()
  local src = debug.getinfo(1, "S").source:match("^@(.+)$")
  return src:match("^(.*)[/\\][^/\\]+$")
end

local M = dofile(plugin_dir() .. "/manifest.lua")
M.config = {}

function M.init(core, config)
  core.log("%s loaded")
end

function M.unload()
end

return M
]], name)

  files[base .. "/manifest.lua"] = string.format([[return {
  name = %q,
  version = "0.1.0",
  description = %q,
  category = %q,
  type = "plugin",
  essential = false,
  dependencies = {},
  min_cdin_version = "0.5.0",
}
]], name, "A CDIN extension", category)

  files[base .. "/README.md"] = string.format([[# %s

A CDIN-X extension.

## Usage

Document the extension here.

## Development

Test locally from the CDIN-X manager before submitting a pull request.
]], name)
end

for path, content in pairs(files) do
  local f, err = io.open(path, "w")
  if not f then
    error(err)
  end
  f:write(content)
  f:close()
  print("Created: " .. path)
end
