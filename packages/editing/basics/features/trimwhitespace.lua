-- Trim trailing whitespace before every save, and on demand.
--
-- One command and one document hook, and both are undone by handing back the
-- same table that was added: `keymap` and `command` removals compare by identity,
-- so a table built fresh at removal time would silently do nothing.
local core    = require "core"
local command = require "core.input.command"
local Doc     = require "core.doc"

local M = {}

local function trim_trailing_whitespace(doc)
  local cline, ccol = doc:get_selection()
  for i = 1, #doc.lines do
    local old_text = doc:get_text(i, 1, i, math.huge)
    local new_text = old_text:gsub("%s*$", "")

    -- Not past the end of the cursor's own line: a caret in the whitespace being
    -- trimmed would otherwise be left past the end of the line.
    if cline == i and ccol > #new_text then
      new_text = old_text:sub(1, ccol - 1)
    end

    if old_text ~= new_text then
      doc:insert(i, 1, new_text)
      doc:remove(i, #new_text + 1, i, math.huge)
    end
  end
end

-- Hoisted so `disable` can hand back this exact table. Building it inline, as
-- this did before, means the removal has nothing to match.
local COMMANDS = {
  ["trim-whitespace:trim-trailing-whitespace"] = function()
    trim_trailing_whitespace(core.active_view.doc)
  end,
}

local enabled = false

--- Whether a function is in one of the document hook lists.
local function remove_hook(list, fn)
  for i = #list, 1, -1 do
    if list[i] == fn then
      table.remove(list, i)
      return true
    end
  end
  return false
end

function M.enable()
  if enabled then return end
  enabled = true

  command.add("core.views.docview", COMMANDS)
  table.insert(Doc._before_save, trim_trailing_whitespace)
end

function M.disable()
  if not enabled then return end
  enabled = false

  command.remove("core.views.docview", COMMANDS)
  remove_hook(Doc._before_save, trim_trailing_whitespace)
end

return M