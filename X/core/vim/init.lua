-- Manifest fields (name, version, description, ...) live inline below --
-- this used to be a separate manifest.lua that init.lua dofile'd; now
-- it's just the top of the returned table, same as any single-file
-- plugin. Everything else in this directory (the sibling .lua modules
-- this file requires) is unchanged.
local M = {
  name = "vim",
  version = "0.1.0",
  description = "Vim-style modal editing, commands, file menu and shell integration",
  author = "cdin Team",
  license = "MIT",
  category = "core",
  type = "plugin",
  essential = true,
  dependencies = { "git" },
  min_cdin_version = "0.5.0",
  tags = { "essential", "editor", "vim", "input" },
}
M.config = { vim_mode_enabled = true }

local loaded = false
function M.init(core, config)
  if loaded then return end
  loaded = true
  require "X.core.vim.ex"
  require "X.core.vim.fmenu"
  require "X.core.vim.shell"
  require "X.core.vim.vimode"
  core.log("Vim extension loaded")
end
function M.unload() end
return M
