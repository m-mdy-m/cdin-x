-- Vim window integration: teaches vim mode about cdin's window manager.
--
-- The window vocabulary lives here rather than in X/core/vim because
-- window layout is a separate capability — vim core must not know it
-- exists. Three pieces:
--   commands.lua  :split / :vsplit / :vnew / :close / :only
--   keymap.lua    the Ctrl+W character map and Tab-to-next-pane
--
-- Both register into X.core.vim.registry, so this integration is the only
-- place that mentions X.core.window.
--
-- The manifest is inline, and nothing is required at the top of the file,
-- so the extension catalog can dofile() this to read the manifest without
-- loading the window manager for a plugin that may never be installed.
local M = {
  name = "vim-window",
  version = "0.2.0",
  description = "Vim window commands backed by the CDIN window plugin",
  author = "cdin Team",
  license = "MIT",
  category = "integration",
  type = "plugin",
  essential = false,
  dependencies = { "vim", "window" },
  min_cdin_version = "0.5.0",
  tags = { "vim", "window", "integration" },
}

local loaded = false

function M.init()
  if loaded then return end
  loaded = true
  require("X.integration.vim.vim-window.commands").register()
  require("X.integration.vim.vim-window.keymap").register()
end

function M.unload()
  if not loaded then return end
  require("X.integration.vim.vim-window.keymap").unregister()
  require("X.integration.vim.vim-window.commands").unregister()
  loaded = false
end

return M
