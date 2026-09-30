-- The vim menu itself: its context, and the entries it shows.
--
-- The menu is built on the generic menu capability (X.core.menu), which
-- knows nothing about files, shells or vim. This module only supplies the
-- context and the entry list; other integrations extend the same menu
-- through menu.extend (see vim-search, vim-treeview, vim-git).
local core  = require "core"
local fs    = require "core.fs"
local menu  = require "X.core.menu.impl"
local files = require "X.integration.vim.vim-menu.files"

local M = {}

M.NAME = "vim.main"

local function shell() return require "X.core.vim.shell" end

-- What the menu is acting on: the current file's directory if a document
-- is open, otherwise the working directory.
local function context()
  local av = core.active_docview()
  if av and av.doc and av.doc.filename then
    local file = av.doc.filename
    return {
      dir = files.dirname(file), file = file, is_dir = false,
      label = files.basename(file) or file,
    }
  end
  local cwd = fs.pwd()
  return { dir = cwd, file = nil, is_dir = true, label = files.basename(cwd) or cwd }
end

-- The shell escape used by the Build and Shell sections.
local function shell_buffer(cmd)
  return function() shell().run_in_buffer(cmd) end
end

local function network_info()
  local out = shell().capture("ip addr 2>/dev/null || ifconfig 2>/dev/null")
  if not out or out == "" then
    out = shell().capture("ipconfig 2>nul") or "no output"
  end
  local doc = require("core.doc")()
  doc:text_input("-- network info\n\n" .. out)
  doc:set_selection(1, 1)
  -- Command output, not a file the user edited. Without clean() the doc stays
  -- dirty and every :q after :net offers to discard "unsaved changes" to it.
  doc:clean()
  function doc:get_name() return ":net" end
  core.root_view:open_doc(doc)
end

local function entries(ctx)
  local dir   = ctx.dir
  local file  = ctx.file
  local label = files.basename(file or dir) or dir or "."

  return {
    { header = "Files  [" .. label .. "]", entries = {
      { key = "n", label = "New File",       info = "in " .. label,   action = function() files.new_file(dir) end },
      { key = "N", label = "New Directory",  info = "mkdir",           action = function() files.new_dir(dir) end },
      { key = "o", label = "Open File",      info = "browse & open",  action = function() files.open_file(dir) end },
      { key = "r", label = "Rename",         info = label,            action = function() files.rename(file, dir) end },
      { key = "y", label = "Copy",           info = label,            action = function() files.copy(file, dir) end },
      { key = "v", label = "Move",           info = label,            action = function() files.move(file, dir) end },
      { key = "x", label = "Delete",         info = label,            action = function() files.delete(file, dir) end },
    }},
    { header = "Navigate", entries = {
      { key = "f", label = "Change Directory",   info = "cd",  action = function() M.change_dir_prompt(dir) end },
      { key = "u", label = "Up One Level",       info = "cd ..", action = function() files.change_dir(files.dirname(dir)) end },
      { key = ".", label = "Current Directory",  info = dir or ".", action = function() core.log(dir or fs.pwd()) end },
      { key = "w", label = "Working Directory",  info = "pwd",  action = shell_buffer("pwd") },
    }},
    { header = "Build", entries = {
      { key = "m", label = "Make",     info = "make",      action = shell_buffer("make") },
      { key = "t", label = "Run Tests", info = "make test", action = shell_buffer("make test") },
    }},
    { header = "Shell", entries = {
      { key = "!", label = "Custom Command", info = "type any shell command", action = function() shell().prompt_and_run() end },
      { key = "e", label = "Environment",     info = "env",  action = shell_buffer("env") },
      { key = "i", label = "Network Info",    info = "ip addr / ifconfig", action = network_info },
    }},
  }
end

function M.change_dir_prompt(dir)
  local common = require "core.utils.common"
  core.command_view:enter("Change directory to", function(path)
    if path == "" then return end
    files.change_dir(path)
  end, function(partial) return common.path_suggest(partial) end)
  if dir and dir ~= "." then core.command_view:set_text(dir) end
end

function M.register()
  menu.define(M.NAME, { title = "Menu", context = context, entries = entries })
end

function M.unregister() end

return M
