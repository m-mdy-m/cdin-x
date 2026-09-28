local core = require "core"
local C = require "X.core.window.manager.context"
local M = {}

function M.focus(direction)
  local leaf = C.find_adjacent(direction)
  if leaf then
    leaf:set_active_view(leaf.active_view)
    C.emit("window:focus", { direction = direction })
  end
end

function M.focus_next()
  local leaves = C.collect_leaves(C.root())
  if #leaves < 2 then return end
  local cur = C.active_node()
  for i, leaf in ipairs(leaves) do
    if leaf == cur then
      local next = leaves[(i % #leaves) + 1]
      next:set_active_view(next.active_view)
      return
    end
  end
end

function M.focus_prev()
  local leaves = C.collect_leaves(C.root())
  if #leaves < 2 then return end
  local cur = C.active_node()
  for i, leaf in ipairs(leaves) do
    if leaf == cur then
      local prev = leaves[((i - 2) % #leaves) + 1]
      prev:set_active_view(prev.active_view)
      return
    end
  end
end

function M.focus_prev_window()
  if core.last_active_view then
    local leaf = C.root():get_node_for_view(core.last_active_view)
    if leaf and not leaf.locked then leaf:set_active_view(core.last_active_view) end
  end
end

function M.focus_first()
  local leaves = C.collect_leaves(C.root())
  if leaves[1] then leaves[1]:set_active_view(leaves[1].active_view) end
end

function M.focus_last()
  local leaves = C.collect_leaves(C.root())
  local leaf = leaves[#leaves]
  if leaf then leaf:set_active_view(leaf.active_view) end
end

return M
