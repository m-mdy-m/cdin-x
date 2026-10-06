local core = require "core"
local common = require "core.utils.common"
local config = require "core.config"
local DocView = require "core.views.docview"

local M = {
  core = core,
  common = common,
  config = config,
  DocView = DocView,
  max_previous_finds = 50,
}

M.state = {
  previous_finds = {},
  last_doc = nil,
  last_fn = nil,
  last_text = nil,
}

local highlight_map = setmetatable({}, { __mode = "k" })

function M.doc()
  return core.active_view.doc
end

function M.is_doc_view()
  return core.active_view and core.active_view:is(DocView)
end

function M.has_selection()
  return M.is_doc_view() and core.active_view.doc:has_selection()
end

function M.get_highlight(doc)
  return highlight_map[doc]
end

function M.set_highlight(doc, text, opt)
  if text and text ~= "" then
    highlight_map[doc] = { text = text, opt = opt }
  else
    highlight_map[doc] = nil
  end
  core.redraw = true
end

function M.clear_highlight(doc)
  highlight_map[doc] = nil
  core.redraw = true
end

function M.clear_find_state()
  M.state.previous_finds = {}
  M.state.last_doc = nil
  M.state.last_fn = nil
  M.state.last_text = nil
end

function M.push_previous_find(doc, selection)
  local state = M.state

  if state.last_doc ~= doc then
    state.last_doc = doc
    state.previous_finds = {}
  end

  if #state.previous_finds >= M.max_previous_finds then
    table.remove(state.previous_finds, 1)
  end

  table.insert(state.previous_finds, selection or { doc:get_selection() })
end

function M.set_last_find(doc, fn, text)
  M.state.last_doc = doc
  M.state.last_fn = fn
  M.state.last_text = text
end

function M.has_active_find()
  return M.is_doc_view() and M.state.last_fn ~= nil
end

function M.get_last_find()
  return M.state.last_doc, M.state.last_fn, M.state.last_text
end

function M.clear_doc_search(doc)
  doc = doc or M.doc()
  M.clear_highlight(doc)
  M.state.last_fn = nil
  M.state.last_text = nil
end

return M
