-- Vim mode's load point: it takes over key dispatch and delegates every
-- decision to keys.lua, then wires up the sub-modules that make up the
-- feature.
--
-- Layout of this directory:
--   init.lua     patches keymap.on_key_pressed; the single load point
--   keys.lua     normal/visual key handling and vim's own vocabulary
--   mode.lua     per-view mode state (normal/insert/visual) + label
--   motions.lua  the motion keys h/j/k/l/w/b/e
--   status.lua   the mode pill and the home-screen help entries
local core    = require "core"
local config  = require "core.config"
local keymap  = require "core.input.keymap"
local keys    = require "X.core.vim.vimode.keys"
local mode    = require "X.core.vim.vimode.mode"
local status  = require "X.core.vim.vimode.status"

local M = {}

local original_on_key_pressed = keymap.on_key_pressed

function core.get_vim_mode_label()
  if not config.vim_mode_enabled then return nil end
  local view = core.active_docview()
  if not view then return nil end
  return mode.label(view)
end

function M.register()
  status.register()

  keymap.on_key_pressed = function(k)
    local ok, handled = core.try(keys.handle_key, k)
    if ok and handled then
      if system.suppress_next_textinput then
        system.suppress_next_textinput()
      end
      return true
    end
    return original_on_key_pressed(k)
  end
end

function M.unregister()
  keymap.on_key_pressed = original_on_key_pressed
  keys.reset()
end

return M
