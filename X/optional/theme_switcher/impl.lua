local core    = require "core"
local config  = require "core.config"
local common  = require "core.utils.common"
local command = require "core.input.command"
local keymap  = require "core.input.keymap"
local style   = require "core.style"

local M = {}

local _on_change = {}

function M.on_change(fn)
  _on_change[#_on_change + 1] = fn
  return fn
end

function M.off_change(fn)
  for i, f in ipairs(_on_change) do
    if f == fn then table.remove(_on_change, i); return end
  end
end

function M.emit_change(name)
  for _, fn in ipairs(_on_change) do core.try(fn, name) end
end

local function change_theme()
  local ok, themes = pcall(require, "core.themes")
  if not ok or not themes then core.error("themes module missing"); return end

  core.command_view:enter("Change Theme", function(_, item)
    local name = item and item.text or nil
    if not name then return end
    if not style.set_theme(name) then
      core.error("Unknown theme: %s", name)
      return
    end
    config.theme = name
    M.emit_change(name)
    core.log("Theme: %s", name)
    core.redraw = true
  end, function(text)
    return common.fuzzy_match(themes.names(), text)
  end)
end

local MAP = { ["core:change-theme"] = change_theme }
local NAMES = { "core:change-theme" }

local KEYS = { ["ctrl+alt+t"] = "core:change-theme" }

function M.register()
  command.add(nil, MAP, true)
  keymap.add(KEYS)
end

function M.unregister()
  keymap.remove(KEYS)
  command.remove(NAMES)
end

return M
