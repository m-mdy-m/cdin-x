-- Autocomplete commands: accept the selected suggestion, move the
-- selection, or dismiss the box.
--
-- All four are scoped to "a document view is active and something is being
-- suggested", so they only appear in the command palette while the popup is
-- actually up.
local command = require "core.input.command"
local api     = require "X.core.autocomplete.api"

local M = {}

local function has_suggestions()
  return #api.suggestions > 0
end

local function active_doc()
  local view = require("core").active_docview()
  return view and view.doc or nil
end

local MAP = {
  -- Replace the partial word with the selected suggestion. The insert
  -- happens first so the caret lands after the inserted text, then the
  -- partial is removed from in front of it.
  ["autocomplete:complete"] = function()
    local doc = active_doc()
    if not doc then return end
    local line, col = doc:get_selection()
    local text = api.suggestions[api.suggestions_idx].text
    doc:insert(line, col, text)
    doc:remove(line, col, line, col - #api.partial)
    doc:set_selection(line, col + #text - #api.partial)
    api.reset()
  end,

  ["autocomplete:previous"] = function()
    api.suggestions_idx = math.max(api.suggestions_idx - 1, 1)
  end,

  ["autocomplete:next"] = function()
    api.suggestions_idx = math.min(api.suggestions_idx + 1, #api.suggestions)
  end,

  ["autocomplete:cancel"] = function()
    api.reset()
  end,
}

local NAMES = {
  "autocomplete:complete", "autocomplete:previous",
  "autocomplete:next", "autocomplete:cancel",
}

local PREDICATE = function()
  return require("core").active_docview() ~= nil and has_suggestions()
end

function M.register()
  command.add(PREDICATE, MAP, true)
end

function M.unregister()
  command.remove(NAMES)
end

return M
