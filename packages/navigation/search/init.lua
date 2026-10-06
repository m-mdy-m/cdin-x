-- Document search/replace and project-wide search.
--
-- This package's modules are named after it: `require "search.buffer"`. The
-- kernel's searcher resolves the first component against the active catalog, so
-- where the package lives on disk is not part of any require in here.
--
-- Requires go inside init(), not at the top: init.lua is the entry point the
-- kernel dofile()s, and a top-level require would run this package's modules
-- before anything asked for them.
local M = {}

M.config = {}

local loaded = false

function M.init(core, config)
  if loaded then return end
  loaded = true

  local manager = require "search.manager"
  local buffer  = require "search.buffer"
  local project = require "search.project"

  require("search.commands").register()
  require("search.keymap").register()

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
  require("search.keymap").unregister()
  require("search.commands").unregister()

  local core = require "core"
  core.findreplace = nil
  core.search = nil

  loaded = false
end

return M