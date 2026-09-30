local name = arg[1]
local category = arg[2] or "utils"

if not name or not name:match("^[%w%._%-]+$") then
  print("Usage: lua scripts/new-plugin.lua <name> [category]")
  print("  categories: core, integration, optional, syntax")
  print("  For a theme: lua scripts/new-plugin.lua <name> themes")
  os.exit(1)
end

-- `theme` is what people type; the directory is `themes`.
if category == "theme" then category = "themes" end

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
  -- A theme is just theme.lua, in a directory named for the theme. That is
  -- the layout the host's theme registry reads, so this file can be handed
  -- to core.themes.add_root() as-is.
  files[base .. "/theme.lua"] = string.format([[-- %s theme
--
-- A theme is a table of colours, applied by the host's theme registry.
-- `essential = false` keeps it out of the mandatory set a cdin build bundles.
return {
  name = %q,
  essential = false,
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
  -- One file: init.lua carries the manifest inline and the lifecycle.
  --
  -- There is no separate manifest.lua. The catalog reads this file with
  -- dofile() to discover the manifest, so everything else is required inside
  -- init() — a top-level require would run the whole subtree's side effects
  -- just to look the plugin up.
  --
  -- `essential` is false, and it should stay false unless a cdin build is
  -- unusable without this plugin: essential plugins are the ones
  -- scripts/bundle.py copies into a build, and they must be
  -- self-contained. See docs/architecture/extension-contract.md.
  files[base .. "/init.lua"] = string.format([[-- %s
--
-- The manifest is inline. Nothing is required at the top of this file, so
-- the catalog can dofile() it to read the manifest without loading the
-- plugin; requires go inside init().
local M = {
  name = %q,
  version = "0.1.0",
  description = "A CDIN-X extension",
  author = "cdin Team",
  license = "MIT",
  category = %q,
  type = "plugin",
  essential = false,
  dependencies = {},
  min_cdin_version = "0.5.0",
}

M.config = {}

local loaded = false

function M.init(core, config)
  if loaded then return end
  loaded = true
  core.log("%s loaded", M.name)
end

function M.unload()
  if not loaded then return end
  -- Remove whatever init() registered: commands, keymaps, hooks.
  loaded = false
end

return M
]], name, name, category)

  files[base .. "/README.md"] = string.format([[# %s

A CDIN-X extension.

## Usage

Document the extension here.

## Development

Install it into a site with `make link`, then load it from the CDIN-X
manager. Run `make validate` before submitting a pull request.
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