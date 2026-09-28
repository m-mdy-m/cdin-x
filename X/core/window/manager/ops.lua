local core = require "core"
local C = require "X.core.window.manager.context"
local W = {}

local function split(direction, open_new, event_name)
  local node = C.active_node()
  if not node or node.locked then return end
  local view
  if not open_new then
    local DocView = require "core.views.docview"
    local doc = core.active_view and core.active_view.doc
    if doc then view = DocView(doc) end
  end
  node:split(direction, view)
  C.root():update_layout()
  C.emit(event_name, {})
end

function W.split_horizontal(open_new) split("down", open_new, "window:split") end
function W.split_vertical(open_new) split("right", open_new, "window:vsplit") end

function W.new_horizontal()
  local node = C.active_node()
  if not node or node.locked then return end
  node:split("down", nil)
  C.root():update_layout()
  C.emit("window:create", { type = "horizontal" })
end

function W.new_vertical()
  local node = C.active_node()
  if not node or node.locked then return end
  node:split("right", nil)
  C.root():update_layout()
  C.emit("window:create", { type = "vertical" })
end

function W.close()
  local node = C.active_node()
  if not node or node.locked then return end
  if #C.collect_leaves(C.root()) <= 1 then
    core.log("window: only one window open")
    return
  end
  node:close_active_view(C.root())
  C.root():update_layout()
  C.emit("window:close", {})
end

function W.only()
  local current_view = core.active_view
  if not current_view then return end
  if #C.collect_leaves(C.root()) <= 1 then return end

  local Node = require "core.rootview.node"
  local new_leaf = Node()
  new_leaf.views = { current_view }
  new_leaf.active_view = current_view
  local root = C.root()
  if root and root.b and root.b.a then root.b.a = new_leaf end

  root:update_layout()
  core.set_active_view(current_view)
  C.emit("window:close", { type = "only" })
end

local RESIZE_STEP = 0.05

function W.resize_width(delta)
  local node = C.active_node()
  local parent = C.find_split_parent(node, "hsplit")
  if not parent then return end
  local d = (parent.a == node) and delta or -delta
  parent.divider = math.max(0.1, math.min(0.9, parent.divider + d))
  C.root():update_layout()
  C.emit("window:resize", {})
end

function W.resize_height(delta)
  local node = C.active_node()
  local parent = C.find_split_parent(node, "vsplit")
  if not parent then return end
  local d = (parent.a == node) and delta or -delta
  parent.divider = math.max(0.1, math.min(0.9, parent.divider + d))
  C.root():update_layout()
  C.emit("window:resize", {})
end

function W.equalize()
  local function reset(n)
    if not n or n.type == "leaf" then return end
    n.divider = 0.5
    reset(n.a); reset(n.b)
  end
  reset(C.root())
  C.root():update_layout()
  C.emit("window:resize", { type = "equalize" })
end

function W.maximize_width()
  local node = C.active_node()
  local parent = C.find_split_parent(node, "hsplit")
  if not parent then return end
  parent.divider = (parent.a == node) and 0.9 or 0.1
  C.root():update_layout()
end

function W.maximize_height()
  local node = C.active_node()
  local parent = C.find_split_parent(node, "vsplit")
  if not parent then return end
  parent.divider = (parent.a == node) and 0.9 or 0.1
  C.root():update_layout()
end

W.RESIZE_STEP = RESIZE_STEP
return W
