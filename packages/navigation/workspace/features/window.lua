-- Window splits, focus movement and layout sizing.
--
-- Two registrations and two modules, so both are held and both are released: the
-- keymap goes down before the commands, the reverse of the order they went up,
-- because a stroke bound to a command that is already gone is a stroke that does
-- nothing.
local commands = nil
local keymap = nil

local M = {}

local enabled = false

function M.enable()
  if enabled then return end
  enabled = true
  commands = require "workspace.window.commands"
  keymap = require "workspace.window.keymap"
  commands.register()
  keymap.register()
end

function M.disable()
  if not enabled then return end
  enabled = false
  if keymap then keymap.unregister(); keymap = nil end
  if commands then commands.unregister(); commands = nil end
end

return M