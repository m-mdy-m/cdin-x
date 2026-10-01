-- Git commands and a git menu section for Vim mode.
--
-- Runs every git invocation through vim's shell capability
-- (X.core.vim.shell) so output lands in a scratch buffer, and takes the
-- command strings from git's shared recipes (X.core.git.recipes) rather
-- than hardcoding them.
--
--   commands.lua  the vim-git:* commands
--
-- The manifest is inline, and nothing is required at the top of the file,
-- so the extension catalog can dofile() this to read the manifest without
-- loading git for a plugin that may never be installed.
local M = {
  name = "vim-git",
  version = "0.2.0",
  description = "Git commands and Git menu entries for Vim mode",
  author = "cdin Team",
  license = "MIT",
  category = "integration",
  type = "plugin",
  essential = false,
  -- Installing vim-git installs all of these with it: the commands need vim's
  -- shell and git's recipes, and the Git menu section needs menu + vim-menu.
  dependencies = { "vim", "git", "menu", "vim-menu" },
  min_cdin_version = "0.5.0",
  tags = { "vim", "git", "menu", "integration" },
}

local SECTION_ID = "git"
local MENU_ORDER = 30

local loaded = false

-- The menu section is only added when the "vim.main" menu exists, i.e. when
-- both `menu` and `vim-menu` are loaded. Returns the menu module or nil.
local function vim_menu()
  local ok, menu = pcall(require, "X.core.menu.impl")
  if not ok or type(menu) ~= "table" then return nil end
  if not (menu.menus and menu.menus["vim.main"]) then return nil end
  return menu
end

local menu_extended = false

function M.init()
  if loaded then return end
  loaded = true
  require("X.integration.vim.vim-git.commands").register()

  local menu = vim_menu()
  if menu then
    menu.extend("vim.main", SECTION_ID, function()
      return require("X.integration.vim.vim-git.menu").section()
    end, MENU_ORDER)
    menu_extended = true
  end
end

function M.unload()
  if not loaded then return end
  if menu_extended then
    local menu = vim_menu()
    if menu then menu.remove_extension("vim.main", SECTION_ID) end
    menu_extended = false
  end
  require("X.integration.vim.vim-git.commands").unregister()
  loaded = false
end

return M
