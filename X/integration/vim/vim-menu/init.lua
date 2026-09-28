-- Vim menu integration: the "m" key and the menu it opens.
--
-- The menu is a generic capability (X.core.menu) that knows nothing about
-- files, shells or vim. This integration is what binds it to vim mode and
-- supplies vim's own sections; other integrations (vim-search, vim-treeview,
-- vim-git, vim-plugin-manager) extend the same menu with theirs.
--
--   keymap.lua   the "m" normal-mode key
--   commands.lua vim-menu:open / vim-fmenu:open
--   menu.lua     the menu's context and entries
--   files.lua    the file and directory operations those entries run
--
-- The manifest is inline, and nothing is required at the top of the file,
-- so the extension catalog can dofile() this to read the manifest without
-- loading anything for a plugin that may never be installed.
local M = {
  name = "vim-menu",
  version = "0.2.0",
  description = "Vim file, shell and build menu built on the generic menu core",
  author = "cdin Team",
  license = "MIT",
  category = "integration",
  type = "plugin",
  essential = false,
  dependencies = { "vim", "menu" },
  min_cdin_version = "0.5.0",
  tags = { "vim", "menu", "integration" },
}

local loaded = false

function M.init()
  if loaded then return end
  loaded = true
  require("X.integration.vim.vim-menu.menu").register()
  require("X.integration.vim.vim-menu.commands").register()
  require("X.integration.vim.vim-menu.keymap").register()
  require("core").log("Vim menu integration loaded")
end

function M.unload()
  if not loaded then return end
  require("X.integration.vim.vim-menu.keymap").unregister()
  require("X.integration.vim.vim-menu.commands").unregister()
  require("X.integration.vim.vim-menu.menu").unregister()
  loaded = false
end

return M
