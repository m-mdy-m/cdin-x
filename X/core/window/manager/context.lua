local core = require "core"
local M = {}

function M.emit(event, payload)
  core.redraw = true
end

function M.root()
  return core.root_view.root_node
end

function M.active_node()
  local root = M.root()
  return root and root:get_node_for_view(core.active_view) or nil
end

function M.collect_leaves(node, result)
  result = result or {}
  if not node then return result end
  if node.type == "leaf" then
    if not node.locked then result[#result + 1] = node end
  else
    M.collect_leaves(node.a, result)
    M.collect_leaves(node.b, result)
  end
  return result
end

function M.find_adjacent(direction)
  local cur = M.active_node()
  if not cur then return nil end
  local cx = cur.position.x + cur.size.x * 0.5
  local cy = cur.position.y + cur.size.y * 0.5
  local leaves = M.collect_leaves(M.root())
  local best, best_dist = nil, math.huge
  local tolerance = 2

  for _, leaf in ipairs(leaves) do
    if leaf ~= cur then
      local lx = leaf.position.x + leaf.size.x * 0.5
      local ly = leaf.position.y + leaf.size.y * 0.5
      local dx, dy = lx - cx, ly - cy
      local valid = false
      if direction == "right" then
        valid = dx > tolerance and math.abs(dy) <= cur.size.y * 0.5 + leaf.size.y * 0.5
      elseif direction == "left" then
        valid = dx < -tolerance and math.abs(dy) <= cur.size.y * 0.5 + leaf.size.y * 0.5
      elseif direction == "down" then
        valid = dy > tolerance and math.abs(dx) <= cur.size.x * 0.5 + leaf.size.x * 0.5
      elseif direction == "up" then
        valid = dy < -tolerance and math.abs(dx) <= cur.size.x * 0.5 + leaf.size.x * 0.5
      end
      if valid then
        local dist = dx * dx + dy * dy
        if dist < best_dist then best_dist, best = dist, leaf end
      end
    end
  end
  return best
end

function M.find_split_parent(target, split_type)
  local function walk(n)
    if not n or n.type == "leaf" then return nil end
    if (n.a == target or n.b == target) and n.type == split_type then return n end
    return walk(n.a) or walk(n.b)
  end
  return walk(M.root())
end

return M
