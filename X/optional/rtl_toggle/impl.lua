local core    = require "core"
local config  = require "core.config"
local command = require "core.input.command"
local keymap  = require "core.input.keymap"

local M = {}

local MODES = { "auto", "ltr", "rtl" }

local idx = 1
for i, m in ipairs(MODES) do
  if m == (config.direction or "auto") then idx = i break end
end

local MAP = {
  ["rtl:toggle-direction"] = function()
    idx = idx % #MODES + 1
    config.direction = MODES[idx]
    core.log("Text direction: %s (shaping %s)", config.direction,
      config.shaping_enabled ~= false and "on" or "off")
    core.redraw = true
  end,
  ["rtl:toggle-shaping"] = function()
    config.shaping_enabled = not (config.shaping_enabled ~= false)
    core.log("Arabic shaping %s", config.shaping_enabled and "on" or "off")
    core.redraw = true
  end,
}

local NAMES = { "rtl:toggle-direction", "rtl:toggle-shaping" }

local KEYS = {
  ["ctrl+alt+r"] = "rtl:toggle-direction",
  ["ctrl+alt+s"] = "rtl:toggle-shaping",
}

function M.register()
  command.add(nil, MAP, true)
  keymap.add(KEYS, true)
end

function M.unregister()
  keymap.remove(KEYS)
  command.remove(NAMES)
end

return M
