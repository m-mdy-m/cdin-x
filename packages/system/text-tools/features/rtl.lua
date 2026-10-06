-- Toggle right-to-left text direction and Arabic shaping.
--
-- Both keys this writes are *host* config keys, not package options:
-- `config.direction` is what the renderer reads to lay a line out, and
-- `config.shaping_enabled` is what the text layer reads to shape Arabic. That is
-- why they are written at the top level and not namespaced under the package --
-- `config.text_tools.direction` would be a key nothing reads, and the feature
-- would appear to work while changing nothing.
--
-- `idx` is derived from `config.direction` at load, so a direction set in the
-- user's `init.lua` is where the first toggle starts from rather than being
-- overwritten on the first press.
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

-- Hoisted, because removal compares by identity: a table built fresh at removal
-- time matches nothing and the commands survive the feature being switched off.
local MAP = {
  ["rtl:toggle-direction"] = function()
    idx = idx % #MODES + 1
    config.direction = MODES[idx]
    core.log("Text direction: %s (shaping %s)", config.direction,
      config.shaping_enabled ~= false and "on" or "off")
    core.redraw = true
  end,
  ["rtl:toggle-shaping"] = function()
    -- `~= false` first, so `nil` (never set) reads as off and the first press
    -- turns it on rather than turning nil into false and looking like no change.
    config.shaping_enabled = config.shaping_enabled ~= false
    core.log("Arabic shaping %s", config.shaping_enabled and "on" or "off")
    core.redraw = true
  end,
}

local NAMES = { "rtl:toggle-direction", "rtl:toggle-shaping" }

local KEYS = {
  ["ctrl+alt+r"] = "rtl:toggle-direction",
  ["ctrl+alt+s"] = "rtl:toggle-shaping",
}

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