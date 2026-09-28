local core   = require "core"
local style  = require "core.style"
local T      = require "X.core.tab.manager"
local commands = require "X.core.tab.commands"
local keymap   = require "X.core.tab.keymap"

local M = {}

local status_installed = false
local original_get_items = nil

local function install_status_counter()
  if status_installed then return end
  local StatusView = require "core.views.statusview"
  original_get_items = StatusView.get_items
  if not original_get_items then return end

  StatusView.get_items = function(self)
    local left, right = original_get_items(self)

    local total = T.get_count()
    if total < 2 then return left, right end

    local idx = T.get_index(T.active_id) or 1
    right = { table.unpack(right or {}) }
    table.insert(right, StatusView.sep)
    table.insert(right, style.dim)
    table.insert(right, "[")
    table.insert(right, style.accent)
    table.insert(right, idx)
    table.insert(right, style.dim)
    table.insert(right, "/")
    table.insert(right, total)
    table.insert(right, "]")
    table.insert(right, style.text)

    return left, right
  end

  status_installed = true
end

local function remove_status_counter()
  if not status_installed then return end
  local StatusView = require "core.views.statusview"
  StatusView.get_items = original_get_items
  original_get_items = nil
  status_installed = false
end

function M.register()
  commands.register()
  keymap.register()
  install_status_counter()

  core.add_thread(function()
    coroutine.yield(0)
    T.bootstrap()
  end)
end

function M.unregister()
  remove_status_counter()
  keymap.unregister()
  commands.unregister()
end

return M
