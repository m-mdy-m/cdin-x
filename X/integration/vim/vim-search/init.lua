-- Vim search integration: the / n N * keys of vim mode, driven by cdin's
-- search plugin.
--
-- The search keys used to be hardcoded in X/core/vim/vimode.lua. They live
-- here because search is a separate capability; vim core resolves the key
-- and hands it to this integration, which is the only place that mentions
-- X.core.search.
--
-- It also contributes a section to the vim menu, so the search commands
-- are reachable without memorising the keys.
--
-- The manifest is inline, and nothing is required at the top of the file,
-- so the extension catalog can dofile() this to read the manifest without
-- loading anything for a plugin that may never be installed.
-- Dependencies, and why both:
--   menu      the generic menu API this extends (menu.extend)
--   vim-menu  which defines the "vim.main" menu being extended — without it
--             there would be nothing to extend
local M = {
  name = "vim-search",
  version = "0.2.0",
  description = "Search and project-search bindings for Vim mode",
  author = "cdin Team",
  license = "MIT",
  category = "integration",
  type = "plugin",
  essential = false,
  dependencies = { "vim", "search", "menu", "vim-menu" },
  min_cdin_version = "0.5.0",
  tags = { "vim", "search", "integration" },
}

-- Menu entry -> cdin command name. Declared as data rather than as
-- closures so the menu reads as a menu, and so the command names live in
-- exactly one place.
local ENTRIES = {
  { key = "/", label = "Find in Document", info = "find-replace", cmd = "find-replace:find" },
  { key = "n", label = "Repeat Find",      info = "next match",     cmd = "find-replace:repeat-find" },
  { key = "p", label = "Previous Find",    info = "previous match", cmd = "find-replace:previous-find" },
  { key = "P", label = "Find in Project",  info = "ripgrep/find",   cmd = "project-search:find" },
  { key = "F", label = "Project Pattern",  info = "pattern",        cmd = "project-search:find-pattern" },
  { key = "f", label = "Project Fuzzy",    info = "fuzzy",          cmd = "project-search:fuzzy-find" },
}

local SECTION_ID = "search"

local loaded = false

function M.init()
  if loaded then return end
  loaded = true

  local command = require "core.input.command"
  local menu    = require "X.core.menu.impl"

  require("X.integration.vim.vim-search.keymap").register()

  menu.extend("vim.main", SECTION_ID, function()
    local entries = {}
    for _, e in ipairs(ENTRIES) do
      local cmd = e.cmd
      entries[#entries + 1] = {
        key = e.key, label = e.label, info = e.info,
        action = function() command.perform(cmd) end,
      }
    end
    return { header = "Search", entries = entries }
  end, 40)
end

function M.unload()
  if not loaded then return end
  require("X.integration.vim.vim-search.keymap").unregister()
  require("X.core.menu.impl").remove_extension("vim.main", SECTION_ID)
  loaded = false
end

return M
