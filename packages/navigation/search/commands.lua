local command = require "core.input.command"
local buffer  = require "search.buffer"
local project = require "search.project"

local M = {}

-- predicate -> command name -> function, in registration order
local GROUPS = {
  {
    predicate = buffer.predicates.has_selection,
    map = { ["find-replace:select-next"] = buffer.commands.select_next },
  },
  {
    predicate = "core.views.docview",
    map = {
      ["find-replace:find"]            = buffer.commands.find,
      ["find-replace:find-pattern"]    = buffer.commands.find_pattern,
      ["find-replace:clear-highlight"] = buffer.commands.clear_highlight,
      ["find-replace:replace"]         = buffer.commands.replace,
      ["find-replace:replace-pattern"] = buffer.commands.replace_pattern,
      ["find-replace:replace-symbol"]  = buffer.commands.replace_symbol,
    },
  },
  {
    predicate = buffer.predicates.has_active_find,
    map = {
      ["find-replace:repeat-find"]   = buffer.commands.repeat_find,
      ["find-replace:previous-find"] = buffer.commands.previous_find,
    },
  },
  {
    predicate = nil,
    map = {
      ["project-search:find"]         = project.commands.global.find,
      ["project-search:find-pattern"] = project.commands.global.find_pattern,
      ["project-search:fuzzy-find"]   = project.commands.global.fuzzy_find,
    },
  },
  {
    predicate = project.ResultsView,
    map = {
      ["project-search:select-previous"] = project.commands.results.select_previous,
      ["project-search:select-next"]     = project.commands.results.select_next,
      ["project-search:open-selected"]   = project.commands.results.open_selected,
      ["project-search:refresh"]         = project.commands.results.refresh,
    },
  },
}

function M.register()
  for _, group in ipairs(GROUPS) do
    command.add(group.predicate, group.map, true)
  end
end

function M.unregister()
  for _, group in ipairs(GROUPS) do
    local names = {}
    for name in pairs(group.map) do names[#names + 1] = name end
    command.remove(names)
  end
end

return M
