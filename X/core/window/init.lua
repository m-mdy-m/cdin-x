local M = {
  name = "window",
  version = "0.2.0",
  description = "Window splits, focus and layout management",
  author = "cdin Team",
  license = "MIT",
  category = "core",
  type = "plugin",
  essential = false,
  dependencies = {  },
  min_cdin_version = "0.5.0",
  tags = { "essential", "ui", "windows" },
}
M.config = {}

local loaded = false

function M.init(core, config)
  if loaded then return end
  loaded = true
  local commands = require "X.core.window.commands"
  local keymap   = require "X.core.window.keymap"
  commands.register()
  keymap.register()
  core.log("Window extension loaded")
end

function M.unload()
  if not loaded then return end
  require("X.core.window.keymap").unregister()
  require("X.core.window.commands").unregister()
  loaded = false
end
return M
