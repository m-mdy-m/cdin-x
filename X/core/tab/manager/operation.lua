local core = require "core"
local State = require "X.core.tab.manager.index"

local M = {}

function M.bootstrap()
  local tab = State.new_tab("Tab 1")
  tab.root_node = State.editor_node()
  tab.active_view = core.active_view
  State.tabs[tab.id] = tab
  table.insert(State.tab_order, tab.id)
  State.active_id = tab.id
  core.redraw = true
end

function M.create(name, activate)
  local Node = require "core.rootview.node"
  local tab = State.new_tab(name)
  tab.root_node = Node()

  State.tabs[tab.id] = tab
  table.insert(State.tab_order, tab.id)
  core.redraw = true

  if activate ~= false then M.activate(tab.id) end
  return tab.id, tab
end

function M.activate(id)
  if not State.tabs[id] then return false end
  if State.active_id == id then return true end

  State.freeze(State.tabs[State.active_id])
  State.active_id = id
  State.restore(State.tabs[id])
  core.redraw = true
  return true
end

function M.close(id, force)
  id = id or State.active_id
  local tab = State.tabs[id]
  if not tab then return false end

  if tab.pinned and not force then
    core.log("tab: '%s' is pinned — unpin first or use force", tab.name)
    return false
  end
  if #State.tab_order == 1 then
    core.log("tab: cannot close the last tab")
    return false
  end

  table.insert(State.closed_stack, {
    name = tab.name,
    root_node = tab.root_node,
    active_view = tab.active_view,
  })
  if #State.closed_stack > 20 then table.remove(State.closed_stack, 1) end

  if State.active_id == id then
    local idx = M.get_index(id)
    local next_id = State.tab_order[idx + 1] or State.tab_order[idx - 1]
    State.active_id = nil
    M.activate(next_id)
  end

  State.tabs[id] = nil
  for i, tid in ipairs(State.tab_order) do
    if tid == id then table.remove(State.tab_order, i); break end
  end

  core.redraw = true
  return true
end

function M.close_others(keep_id)
  keep_id = keep_id or State.active_id
  for _, id in ipairs({ table.unpack(State.tab_order) }) do
    if id ~= keep_id then M.close(id, true) end
  end
end

function M.close_all()
  for _, id in ipairs({ table.unpack(State.tab_order) }) do M.close(id, true) end
end

function M.reopen_closed()
  if #State.closed_stack == 0 then
    core.log("tab: no closed tabs to reopen")
    return
  end
  local data = table.remove(State.closed_stack)
  local tab = State.new_tab(data.name)
  tab.root_node = data.root_node
  tab.active_view = data.active_view
  State.tabs[tab.id] = tab
  table.insert(State.tab_order, tab.id)
  core.redraw = true
  M.activate(tab.id)
end

function M.rename(id, name)
  local tab = State.tabs[id or State.active_id]
  if not tab then return end
  tab.name = name
  core.redraw = true
end

function M.move(id, to_idx)
  local from_idx = M.get_index(id)
  if not from_idx then return end
  table.remove(State.tab_order, from_idx)
  to_idx = math.max(1, math.min(to_idx, #State.tab_order + 1))
  table.insert(State.tab_order, to_idx, id)
  core.redraw = true
end

function M.pin(id, state)
  local tab = State.tabs[id or State.active_id]
  if not tab then return end
  tab.pinned = (state == nil) and (not tab.pinned) or state
  core.redraw = true
end

function M.duplicate(id)
  id = id or State.active_id
  local src = State.tabs[id]
  if not src then return end
  local new_id = M.create(src.name .. " (copy)", true)

  local files = {}
  local function walk(node)
    if not node then return end
    if node.type == "leaf" then
      for _, v in ipairs(node.views or {}) do
        if v.doc and v.doc.filename then files[#files + 1] = v.doc.filename end
      end
    else
      if node.a then walk(node.a) end
      if node.b then walk(node.b) end
    end
  end
  walk(src.root_node)

  for _, path in ipairs(files) do
    core.try(function() core.root_view:open_doc(core.open_doc(path)) end)
  end
  core.redraw = true
  return new_id
end

function M.next()
  local idx = M.get_index(State.active_id)
  if not idx then return end
  M.activate(State.tab_order[(idx % #State.tab_order) + 1])
end

function M.prev()
  local idx = M.get_index(State.active_id)
  if not idx then return end
  M.activate(State.tab_order[((idx - 2) % #State.tab_order) + 1])
end

function M.go_to(n)
  local id = State.tab_order[n] or State.tab_order[#State.tab_order]
  if id then M.activate(id) end
end

function M.first()
  if State.tab_order[1] then M.activate(State.tab_order[1]) end
end

function M.last()
  if #State.tab_order > 0 then M.activate(State.tab_order[#State.tab_order]) end
end

function M.get_index(id)
  for i, tid in ipairs(State.tab_order) do
    if tid == id then return i end
  end
end

function M.get_active() return State.tabs[State.active_id] end
function M.get_count() return #State.tab_order end

setmetatable(M, {
  __index = function(_, key) return State[key] end,
  __newindex = function(_, key, value) State[key] = value end,
})

return M
