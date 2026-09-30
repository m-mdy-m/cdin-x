-- Vim bindings for the CDIN-X extension manager: the "M" key and a menu
-- section pointing at it.
--
-- The manager itself lives in cdin-x's own runtime (cdinx/), not in X/, so
-- there is no X plugin to depend on for reaching it.
--
-- vim-menu IS a dependency, and the reason is the menu rather than the
-- manager: this extends "vim.main", which vim-menu defines, and
-- menu.extend asserts that the menu exists. Without the declared dependency
-- the load order is arbitrary, and a run that happened to load this first
-- died with `menu is not defined: vim.main`. The manager's topological sort
-- reads `dependencies`, so declaring it is what fixes the order — see
-- cdinx/manager/deps.lua.
--
--   keymap.lua   the "M" normal-mode key
--
-- The manifest is inline, and nothing is required at the top of the file,
-- so the extension catalog can dofile() this to read the manifest without
-- loading anything for a plugin that may never be installed.
local M = {
  name = "vim-plugin-manager",
  version = "0.2.0",
  description = "Vim bindings for the CDIN-X extension manager",
  author = "cdin Team",
  license = "MIT",
  category = "integration",
  type = "plugin",
  essential = false,
  dependencies = { "vim", "menu", "vim-menu" },
  min_cdin_version = "0.5.0",
  tags = { "vim", "plugin-manager", "integration" },
}

local SECTION_ID = "extensions"
local MENU_ORDER = 80

local loaded = false

function M.init()
  if loaded then return end
  loaded = true

  local command = require "core.input.command"
  local menu    = require "X.core.menu.impl"

  require("X.integration.vim.vim-plugin-manager.keymap").register()

  menu.extend("vim.main", SECTION_ID, function()
    return {
      header = "CDIN-X",
      entries = {
        {
          key = "X", label = "Extensions", info = "install, remove, inspect",
          action = function() command.perform("cdin-x:menu") end,
        },
      },
    }
  end, MENU_ORDER)
end

function M.unload()
  if not loaded then return end
  require("X.integration.vim.vim-plugin-manager.keymap").unregister()
  require("X.core.menu.impl").remove_extension("vim.main", SECTION_ID)
  loaded = false
end

return M
