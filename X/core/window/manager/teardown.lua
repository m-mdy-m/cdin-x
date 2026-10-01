-- Closing views: the forced and the wholesale variants.
local core = require "core"
local C    = require "X.core.window.manager.context"

local M = {}

-- Drop the active view from its leaf without asking about unsaved
-- changes.

-- Clear `core.last_active_view`, but only when it still names a view that is
-- actually in the tree.
--
-- `core.set_active_view` asserts on nil, and three callers hand it exactly
-- that: `CommandView:exit`, `StatusView:exit` and `TitleBar:on_mouse_pressed`
-- all do `core.set_active_view(core.last_active_view)`. Blanking the field
-- unconditionally therefore arms a landmine for whatever opens a prompt next.
--
-- That is not hypothetical. `:qa!` runs `close_all_views`, which blanked the
-- field, and `CommandView:submit` had *already* called `exit(true)` -- so
-- `core.quit` was never reached, the prompt stayed open, and
-- `CommandView:update` then called `exit` again on every single frame:
-- an assert raised inside the frame loop forever. The editor froze with Enter
-- dead and no error on screen, because `core.try` swallowed the raise on the
-- keystroke and let the frame loop keep going.
--
-- The rule is therefore: a stale pointer is the one thing this may not leave
-- behind. Anything still in the tree is left alone.
local function forget_last_active(root)
  local last = core.last_active_view
  if last == nil then return end
  if root:get_node_for_view(last) then return end
  core.last_active_view = nil
end

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

  forget_last_active(root)
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

  forget_last_active(root)
  core.redraw = true
  return true
end

return M
