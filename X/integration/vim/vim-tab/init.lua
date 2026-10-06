-- Vim tab integration: teaches vim mode about cdin's tab manager.
--
-- The tab vocabulary lives here rather than in X/core/vim because tabs are
-- a separate capability — vim core must not know they exist. Two pieces:
--   commands.lua  the :tabnew / :tabclose / … ex-commands
--   keymap.lua    the gt / gT normal-mode sequences
--
-- Both register into X.core.vim.registry, so this integration is the only
-- place that mentions workspace.tab.
--
-- The manifest is inline, and nothing is required at the top of the file,
-- so the extension catalog can dofile() this to read the manifest without
-- loading the tab manager for a plugin that may never be installed.
local M = {
  name = "vim-tab",
  version = "0.2.0",
  description = "Vim tab commands backed by the CDIN tab plugin",
  author = "cdin Team",
  license = "MIT",
  category = "integration",
  type = "plugin",
  dependencies = { "vim", "workspace" },
  min_cdin_version = "0.5.0",
  tags = { "vim", "tab", "integration" },
}

local loaded = false

function M.init()
  if loaded then return end
  loaded = true
  require("X.integration.vim.vim-tab.commands").register()
  require("X.integration.vim.vim-tab.keymap").register()
end

function M.unload()
  if not loaded then return end
  require("X.integration.vim.vim-tab.keymap").unregister()
  require("X.integration.vim.vim-tab.commands").unregister()
  loaded = false
end

return M
