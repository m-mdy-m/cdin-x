-- Vim treeview integration: :tree, the tree menu, and a context provider
-- so the vim menu knows which directory the tree is sitting in.
--
-- It also re-scans the tree when the working directory changes, by
-- subscribing to vim's "cwd_changed" event. That event is the reason :cd
-- no longer calls into treeview directly: vim mode announces that the
-- working directory moved and anything caching paths decides for itself
-- what to do about it.
--
-- The manifest is inline, and nothing is required at the top of the file,
-- so the extension catalog can dofile() this to read the manifest without
-- loading anything for a plugin that may never be installed.
local M = {
  name = "vim-treeview",
  version = "0.2.0",
  description = "Treeview navigation and context integration for Vim",
  author = "cdin Team",
  license = "MIT",
  category = "integration",
  type = "plugin",
  essential = false,
  dependencies = { "vim", "treeview", "menu", "vim-menu" },
  min_cdin_version = "0.5.0",
  tags = { "vim", "treeview", "navigation", "integration" },
}

local MENU_SECTION_ID = "treeview"
local CONTEXT_ID      = "treeview"

local TREE_ENTRIES = {
  { key = "e", label = "Focus Tree",    info = "treeview",        cmd = "treeview:focus" },
  { key = "R", label = "Refresh Tree",  info = "re-scan",         cmd = "treeview:focus-and-refresh" },
  { key = "h", label = "Toggle Hidden", info = "hidden files",    cmd = "treeview:toggle-hidden" },
  { key = ".", label = "Reveal",        info = "focus current item", cmd = "treeview:focus-and-refresh" },
}

-- Where the tree's cursor is, as { dir, file, is_dir, label }. nil when
-- no tree view is open or it has no cursor item, which lets the menu fall
-- back to its own context.
local function context()
  local view = require("X.core.treeview.api").get_view()
  if not view or not view.cursor_item then return nil end
  local item = view.cursor_item
  local path = item.abs_filename or item.filename or "."
  if item.type == "dir" then
    return { dir = path, file = nil, is_dir = true, label = item.name or path }
  end
  local dir = path:match("^(.*)[\\/][^\\/]+$") or "."
  return { dir = dir, file = path, is_dir = false, label = item.name or path }
end

-- The tree caches absolute paths, so it has to be told when :cd moves the
-- working directory. Registered as a function value so unregister can
-- hand back exactly what was subscribed.
local function on_cwd_changed()
  require("core.input.command").perform("treeview:refresh")
end

local loaded = false

function M.init()
  if loaded then return end
  loaded = true

  local command = require "core.input.command"
  local core    = require "core"
  local menu    = require "X.core.menu.impl"
  local registry = require "X.core.vim.registry"

  require("X.integration.vim.vim-treeview.commands").register()
  registry.on("cwd_changed", on_cwd_changed)

  menu.set_context_provider("vim.main", CONTEXT_ID, context, 200)

  menu.extend("vim.main", MENU_SECTION_ID, function()
    local entries = {}
    for _, e in ipairs(TREE_ENTRIES) do
      local cmd = e.cmd
      entries[#entries + 1] = {
        key = e.key, label = e.label, info = e.info,
        action = function() command.perform(cmd) end,
      }
    end
    return { header = "Tree", entries = entries }
  end, 20)

  core.log("Vim â†” Treeview integration loaded")
end

function M.unload()
  if not loaded then return end
  local registry = require "X.core.vim.registry"
  local menu     = require "X.core.menu.impl"

  registry.off("cwd_changed", on_cwd_changed)
  require("X.integration.vim.vim-treeview.commands").unregister()
  menu.remove_extension("vim.main", MENU_SECTION_ID)
  menu.remove_context_provider("vim.main", CONTEXT_ID)
  loaded = false
end

return M
