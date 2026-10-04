-- Vim-style modal editing and the ex command line.
--
-- Vim core owns *only* vim's own vocabulary — motions, operators, the
-- ex-commands for files, the shell escape, the mode pill. Anything that
-- needs another plugin's behaviour is an integration under
-- X/integration/vim/, and extends vim through the single registry in
-- registry.lua (ex-commands, the Ctrl+W map, the "g" map, single keys,
-- and events). Nothing in this directory may require another X plugin.
--
-- Layout:
--   init.lua        inline manifest + the one load point
--   registry.lua    the extension points integrations register into
--   commands.lua    vim's own cdin commands
--   keymap.lua      vim's own non-modal key bindings
--   api.lua         legacy alias for registry, kept for old plugins
--   ex/             the ":" command line, split by concern
--   shell/          running shell commands and showing their output
--   vimode/         modal editing: the key reader, motions, text objects,
--                   the operators, mode state, and the status pill
--
-- Integrations live in X/integration/vim/: vim-tab, vim-window,
-- vim-search, vim-treeview, vim-git, vim-menu, vim-plugin-manager.
--
-- Note there is no manifest.lua: the inline table below is the single
-- source of truth. The sibling modules are required inside init() rather
-- than at the top of this file on purpose — the extension catalog reads
-- this file with dofile() to discover the manifest, so a top-level
-- require would drag the whole subtree in, running its side effects,
-- merely to look the plugin up.
local M = {
  name = "vim",
  version = "0.3.3",
  description = "Vim-style modal editing and command-line integration",
  author = "cdin Team",
  license = "MIT",
  category = "core",
  type = "plugin",
  essential = true,
  dependencies = {},
  min_cdin_version = "0.5.0",
  tags = { "essential", "editor", "vim", "input" },
}
M.config = { vim_mode_enabled = true }

local loaded = nil

function M.init(core, config)
  if loaded then return end

  -- Apply this plugin's own default, before anything reads it.
  --
  -- M.config above is a declaration, not an application: nothing in the
  -- runtime copies it onto config, so a default written there and nowhere
  -- else is simply never set. Every gate in vim mode tests
  -- `if not config.vim_mode_enabled then return false end`, so with the
  -- value left nil the key handler bails on the first keystroke and vim mode
  -- is silently off — which looks exactly like "vim is not loaded" and sends
  -- you looking for a key to turn it on with.
  --
  -- The guard is `== nil`, not `=`, so a user who set it in their
  -- ~/.config/cdin/user/init.lua keeps their value. That file runs before
  -- plugins, which is why this works.
  if config.vim_mode_enabled == nil then
    config.vim_mode_enabled = M.config.vim_mode_enabled
  end

  local ex       = require "X.core.vim.ex"
  local vimode   = require "X.core.vim.vimode"
  local commands = require "X.core.vim.commands"
  local keymap   = require "X.core.vim.keymap"
  local shell_commands = require "X.core.vim.shell.commands"
  local shell_keymap   = require "X.core.vim.shell.keymap"

  -- Order matters: the commands and keys have to exist before anything
  -- can trigger them, and ex must have its own commands registered
  -- before the first ":w" can be typed.
  commands.register()
  keymap.register()
  shell_commands.register()
  shell_keymap.register()
  ex.register()
  vimode.register()

  loaded = {
    ex = ex, vimode = vimode, commands = commands, keymap = keymap,
    shell_commands = shell_commands, shell_keymap = shell_keymap,
  }

  core.log("Vim extension loaded")
end

function M.unload()
  if not loaded then return end
  -- Unwind in the reverse order of registration.
  loaded.vimode.unregister()
  loaded.ex.unregister()
  loaded.shell_keymap.unregister()
  loaded.shell_commands.unregister()
  loaded.keymap.unregister()
  loaded.commands.unregister()
  loaded = nil
end

return M
