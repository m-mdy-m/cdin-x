-- Document search, find/replace, and search highlighting.
-- Command wiring lives in commands.lua; default keymaps live in keymap.lua.

local manager = require "X.core.search.manager"
local core = manager.core
local config = manager.config
local DocView = manager.DocView
local search = require "core.doc.search"

local M = {}

function M.get_highlight(d)
  return manager.get_highlight(d)
end

function M.set_highlight(d, text, opt)
  return manager.set_highlight(d, text, opt)
end

function M.clear_highlight(d)
  return manager.clear_highlight(d)
end

core.search = core.search or {}
core.search.buffer = M
core.findreplace = M

local function doc()
  return manager.doc()
end




local function find(label, search_fn, opt)
  local dv = core.active_view
  local sel = { dv.doc:get_selection() }
  local text = dv.doc:get_text(table.unpack(sel))
  local found = false

  core.command_view:set_text(text, true)

  core.command_view:enter(label, function(text)
    if found then
      manager.state.previous_finds = {}
      manager.push_previous_find(dv.doc, sel)
      manager.set_last_find(dv.doc, search_fn, text)
      -- keep highlight alive after closing find bar
      M.set_highlight(dv.doc, text, opt)
    else
      core.error("Couldn't find %q", text)
      dv.doc:set_selection(table.unpack(sel))
      dv:scroll_to_make_visible(sel[1], sel[2])
      M.clear_highlight(dv.doc)
    end

  end, function(text)
    local ok, line1, col1, line2, col2 = pcall(search_fn, dv.doc, sel[1], sel[2], text)
    if ok and line1 and text ~= "" then
      dv.doc:set_selection(line2, col2, line1, col1)
      dv:scroll_to_line(line2, true)
      found = true
      -- live highlight while typing
      M.set_highlight(dv.doc, text, opt)
    else
      dv.doc:set_selection(table.unpack(sel))
      found = false
      if text == "" then M.clear_highlight(dv.doc) end
    end

  end, function(explicit)
    if explicit then
      -- user pressed Escape: clear highlight and restore position
      dv.doc:set_selection(table.unpack(sel))
      dv:scroll_to_make_visible(sel[1], sel[2])
      M.clear_highlight(dv.doc)
    end
  end)
end


local function replace(kind, default, fn)
  core.command_view:set_text(default, true)

  core.command_view:enter("Find To Replace " .. kind, function(old)
    core.command_view:set_text(old, true)

    local s = string.format("Replace %s %q With", kind, old)
    core.command_view:enter(s, function(new)
      local n = doc():replace(function(text)
        return fn(text, old, new)
      end)
      core.log("Replaced %d instance(s) of %s %q with %q", n, kind, old, new)
    end)
  end)
end


local function has_selection()
  return manager.has_selection()
end

local function has_active_find()
  return manager.has_active_find()
end

M.commands = {
  select_next = function()
    local l1, c1, l2, c2 = doc():get_selection(true)
    local text = doc():get_text(l1, c1, l2, c2)
    local l1, c1, l2, c2 = search.find(doc(), l2, c2, text, { wrap = true })
    if l2 then doc():set_selection(l2, c2, l1, c1) end
  end,

  find = function()
    local opt = { wrap = true, no_case = true }
    find("Find Text", function(doc, line, col, text)
      return search.find(doc, line, col, text, opt)
    end, opt)
  end,

  find_pattern = function()
    local opt = { wrap = true, no_case = true, pattern = true }
    find("Find Text Pattern", function(doc, line, col, text)
      return search.find(doc, line, col, text, opt)
    end, opt)
  end,

  clear_highlight = function()
    manager.clear_doc_search(doc())
  end,

  replace = function()
    replace("Text", "", function(text, old, new)
      return text:gsub(old:gsub("%W", "%%%1"), new:gsub("%%", "%%%%"), nil)
    end)
  end,

  replace_pattern = function()
    replace("Pattern", "", function(text, old, new)
      return text:gsub(old, new)
    end)
  end,

  replace_symbol = function()
    local first = ""
    if doc():has_selection() then
      local text = doc():get_text(doc():get_selection())
      first = text:match(config.symbol_pattern) or ""
    end
    replace("Symbol", first, function(text, old, new)
      local n = 0
      local res = text:gsub(config.symbol_pattern, function(sym)
        if old == sym then
          n = n + 1
          return new
        end
      end)
      return res, n
    end)
  end,

  repeat_find = function()
    local current_doc = doc()
    local line, col = current_doc:get_selection()
    local _, last_fn, last_text = manager.get_last_find()
    local line1, col1, line2, col2 = last_fn(current_doc, line, col, last_text)
    if line1 then
      manager.push_previous_find(current_doc)
      current_doc:set_selection(line2, col2, line1, col1)
      core.active_view:scroll_to_line(line2, true)
    end
  end,

  previous_find = function()
    local current_doc = doc()
    local last_doc = manager.state.last_doc
    if current_doc ~= last_doc or #manager.state.previous_finds == 0 then
      core.error("No previous finds")
      return
    end
    local sel = table.remove(manager.state.previous_finds)
    current_doc:set_selection(table.unpack(sel))
    core.active_view:scroll_to_line(sel[3], true)
  end,
}

M.predicates = {
  has_selection = has_selection,
  has_active_find = has_active_find,
}

return M
