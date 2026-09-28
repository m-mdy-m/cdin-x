-- Closing views: the forced and the wholesale variants.
local core = require "core"
local C    = require "X.core.window.manager.context"

local M = {}

-- Drop the active view from its leaf without asking about unsaved
-- changes. 
function M.close_active_view()
  local root = C.root()
  local node = core.root_view:get_active_node()
  if not node then return false end

  if #node.views > 1 then
    local idx = node:get_view_idx(node.active_view)
    table.remove(node.views, idx)
    node:set_active_view(node.views[idx] or node.views[#node.views])
  else
    local parent = node:get_parent_node(root)
    local is_a   = (parent.a == node)
    local other  = parent[is_a and "b" or "a"]
    if other:get_locked_size() then
      -- The sibling is pinned, so this leaf cannot be removed. Leave it
      -- holding one fresh view rather than nothing.
      node.views = {}
      node:add_view(require("core.views.view")())
    else
      parent:consume(other)
      local leaf = parent
      while leaf.type ~= "leaf" do leaf = leaf[is_a and "a" or "b"] end
      leaf:set_active_view(leaf.active_view)
    end
  end

  core.last_active_view = nil
  root:update_layout()
  core.redraw = true
  return true
end

local function count_unlocked_views(node)
  if not node then return 0 end
  if node.type == "leaf" then
    return node.locked and 0 or #node.views
  end
  return count_unlocked_views(node.a) + count_unlocked_views(node.b)
end

local function first_unlocked_leaf(node)
  if not node then return nil end
  if node.type == "leaf" then
    return (not node.locked) and node or nil
  end
  return first_unlocked_leaf(node.a) or first_unlocked_leaf(node.b)
end

-- Close every unlocked view, leaving a single empty view behind, then
-- garbage-collect any document nothing references any more.
--
-- The caller is responsible for having dealt with unsaved changes: this
-- discards them. That is what makes it the right target for :qa! and for
-- the window:close-all-views command, and the wrong one for :q.
function M.close_all_views()
  local root = C.root()

  -- If focus is sitting in a locked leaf, move it somewhere closable
  -- first, otherwise the loop below cannot make progress.
  if core.root_view:get_active_node().locked then
    local leaf = first_unlocked_leaf(root)
    if leaf then leaf:set_active_view(leaf.active_view) end
  end

  local guard = 0
  while count_unlocked_views(root) > 1 and guard < 1000 do
    guard = guard + 1
    if core.root_view:get_active_node().locked then break end
    M.close_active_view()
  end

  local node = core.root_view:get_active_node()
  if node and not node.locked then
    node.views = {}
    node:add_view(require("core.rootview.empty_view")())
  end

  for i = #core.docs, 1, -1 do
    local doc = core.docs[i]
    if #core.get_views_referencing_doc(doc) == 0 then
      table.remove(core.docs, i)
    end
  end

  core.last_active_view = nil
  core.redraw = true
  return true
end

return M
