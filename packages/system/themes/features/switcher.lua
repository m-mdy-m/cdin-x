-- The theme switcher: pick a theme from a searchable list.
--
-- `config.theme` is a *host* key -- the host applies it, before plugins run and
-- once more after -- so it is written at the top level and not namespaced. The
-- same reasoning as the rtl feature: `config.text_tools.direction` would be a key
-- nothing reads.
--
-- `on_change` / `off_change` are the package's own seam. A `with` entry -- the
-- session's, which persists the choice -- subscribes here rather than reaching
-- into this file, which is why they are public rather than a local list.
local core    = require "core"
local config  = require "core.config"
local common  = require "core.utils.common"
local command = require "core.input.command"
local keymap  = require "core.input.keymap"
local style   = require "core.style"

local M = {}

local listeners = {}

--- Subscribes to a theme change. Returns `fn` so the caller can hand the same
--- value back to `off_change` -- removal compares by identity, so a function
--- built fresh at removal time matches nothing.
--- @param fn fun(name: string)
--- @return fun(name: string)
function M.on_change(fn)
  listeners[#listeners + 1] = fn
  return fn
end

--- @param fn fun(name: string)
function M.off_change(fn)
  for i, f in ipairs(listeners) do
    if f == fn then
      table.remove(listeners, i)
      return
    end
  end
end

--- @param name string
function M.emit_change(name)
  for _, fn in ipairs(listeners) do core.try(fn, name) end
end

local function change_theme()
  local ok, theme_registry = pcall(require, "core.themes")
  if not ok or not theme_registry then core.error("themes module missing"); return end

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
    return common.fuzzy_match(theme_registry.names(), text)
  end)
end

-- Hoisted so `disable` hands back this exact table.
local MAP = { ["core:change-theme"] = change_theme }
local NAMES = { "core:change-theme" }

local KEYS = { ["ctrl+alt+t"] = "core:change-theme" }

local enabled = false

function M.enable()
  if enabled then return end
  enabled = true
  command.add(nil, MAP, true)
  keymap.add(KEYS)
end

function M.disable()
  if not enabled then return end
  enabled = false
  keymap.remove(KEYS)
  command.remove(NAMES)
end

return M