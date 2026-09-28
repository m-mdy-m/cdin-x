-- Document search/replace and project-wide search.
local M = {
  name = "search",
  version = "0.2.0",
  description = "Document search/replace and project-wide search",
  author = "cdin Team",
  license = "MIT",
  category = "core",
  type = "plugin",
  essential = false,
  dependencies = {},
  min_cdin_version = "0.5.0",
  tags = { "search", "find", "replace", "project" },
}
M.config = {}

local loaded = false

function M.init(core, config)
  if loaded then return end
  loaded = true

  local manager = require "X.core.search.manager"
  local buffer  = require "X.core.search.buffer"
  local project = require "X.core.search.project"

  require("X.core.search.commands").register()
  require("X.core.search.keymap").register()

  core.search = core.search or {}
  core.search.buffer  = buffer
  core.search.project = project
  core.search.manager = manager
  -- legacy alias kept for configs and integrations written before the
  -- rename; same table as core.search.buffer
  core.findreplace = buffer

  core.log("Search extension loaded")
end

function M.unload()
  if not loaded then return end
  require("X.core.search.keymap").unregister()
  require("X.core.search.commands").unregister()

  local core = require "core"
  core.findreplace = nil
  core.search = nil

  loaded = false
end

return M
