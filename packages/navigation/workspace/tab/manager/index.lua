local core = require "core"

local M = {
  tabs = {},
  tab_order = {},
  active_id = nil,
  closed_stack = {},
  next_id = 1,
}

function M.new_tab(name)
  local id = M.next_id
  M.next_id = M.next_id + 1
  return {
    id = id,
    name = name or ("Tab " .. id),
    root_node = nil,
    active_view = nil,
    pinned = false,
  }
end

function M.editor_slot()
  local rn = core.root_view.root_node
  if not (rn and rn.b and rn.b.a) then return nil, nil end
  local ea = rn.b.a
  if ea.type == "leaf" then return rn.b, "a" end
  if ea.b and not ea.b.locked then return ea, "b" end
  if ea.a and not ea.a.locked then return ea, "a" end
  return rn.b, "a"
end

function M.editor_node()
  local parent, key = M.editor_slot()
  if parent then return parent[key] end

  local function find_unlocked(n)
    if not n then return nil end
    if n.type == "leaf" then return (not n.locked) and n or nil end
    return find_unlocked(n.a) or find_unlocked(n.b)
  end

  return find_unlocked(core.root_view.root_node)
end

function M.set_editor_node(node)
  local parent, key = M.editor_slot()
  if parent then parent[key] = node end
end

function M.freeze(tab)
  if not tab then return end
  tab.root_node = M.editor_node()
  tab.active_view = core.active_view
end

function M.restore(tab)
  if not tab then return end
  M.set_editor_node(tab.root_node)
  core.root_view.root_node:update_layout()

  local av = tab.active_view
  if av then
    local node = core.root_view.root_node:get_node_for_view(av)
    if node then
      node:set_active_view(av)
      return
    end
  end

  local function first_unlocked_leaf(n)
    if not n then return nil end
    if n.type == "leaf" then return (not n.locked) and n or nil end
    return first_unlocked_leaf(n.a) or first_unlocked_leaf(n.b)
  end

  local leaf = first_unlocked_leaf(core.root_view.root_node)
  if leaf then leaf:set_active_view(leaf.active_view) end
end

return M
