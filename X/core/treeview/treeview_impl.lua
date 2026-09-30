local core    = require "core"
local common  = require "core.utils.common"
local command = require "core.input.command"
local config  = require "core.config"
local keymap  = require "core.input.keymap"
local style   = require "core.style"
local Doc     = require "core.doc"
local project = require "core.project"
local View    = require "core.views.view"

local Cache = require "X.core.treeview.cache"
local API   = require "X.core.treeview.api"
local Nav   = require "X.core.treeview.nav"
local Build = require "X.core.treeview.tree.build"
local Ops   = require "X.core.treeview.tree.operations"
local RO    = require "X.core.treeview.readonly"

-- project.lua no longer reaches into this plugin directly; it exposes a
-- hook array instead (project._after_root_change) and we register here,
-- at load time, the same way session.lua registers into Doc._after_load.
table.insert(project._after_root_change, function()
  Cache.flush()
end)

-- Defaults, guarded so a user who set them in their own init.lua keeps their
-- value. Assigning unconditionally would silently overwrite a config the user
-- can see working in their file.
if config.treeview_size == nil then
  config.treeview_size = 200 * SCALE
end
if config.show_hidden_files == nil then
  config.show_hidden_files = true
end

if config.show_hidden_files then
  config.ignore_files = "^$"
end

local TreeView = View:extend()

function TreeView:new()
  TreeView.super.new(self)
  self.scrollable        = true
  self.visible           = true
  self.init_size         = true
  self.selected          = {}
  self.last_clicked      = nil
  self.cursor_item       = nil
  self._last_project_files = nil
end

function TreeView:get_name() return "Project" end

function TreeView:get_item_height()
  return style.font:get_height() + style.padding.y
end

function TreeView:get_cached(item)
  return Build.get_cached(self, item)
end

function TreeView:each_item()
  return Build.each_item(self)
end

function TreeView:on_mouse_moved(px, py, ...)
  TreeView.super.on_mouse_moved(self, px, py, ...)
  self.hovered_item = nil
  for item, x, y, w, h in self:each_item() do
    if px > x and py > y and px <= x+w and py <= y+h then
      self.hovered_item = item
      break
    end
  end
  self.cursor = self.hovered_item and "hand" or "arrow"
end

function TreeView:toggle_select(item, additive)
  if not additive then self.selected = {} end
  if self.selected[item.abs_filename] then
    self.selected[item.abs_filename] = nil
  else
    self.selected[item.abs_filename] = item
  end
end

function TreeView:on_mouse_pressed(button, x, y, clicks)
  if TreeView.super.on_mouse_pressed(self, button, x, y, clicks) then return true end
  if not self.hovered_item then
    if not keymap.modkeys.ctrl and not keymap.modkeys.shift then
      self.selected = {}
    end
    return
  end

  local item = self.hovered_item
  self.cursor_item = item

  if keymap.modkeys.ctrl then
    self:toggle_select(item, true)
    return
  elseif keymap.modkeys.shift and self.last_clicked then
    local items, in_range = {}, false
    for it in self:each_item() do
      if it == self.last_clicked or it == item then
        in_range = not in_range or it == item
        items[#items+1] = it
      elseif in_range then
        items[#items+1] = it
      end
    end
    self.selected = {}
    for _, it in ipairs(items) do self.selected[it.abs_filename] = it end
    return
  end

  self.selected     = { [item.abs_filename] = item }
  self.last_clicked = item

  if item.type == "dir" then
    item.expanded = not item.expanded
    if item.expanded then
      local project = require "core.project"
      project.prioritize(item.filename)
    end
  else
    core.try(function()
      core.root_view:open_doc(core.open_doc(item.filename))
    end)
  end
end

function TreeView:get_item_list()       return Nav.get_item_list(self) end
function TreeView:ensure_cursor()       return Nav.ensure_cursor(self) end
function TreeView:scroll_to_cursor()    Nav.scroll_to_cursor(self) end
function TreeView:move_cursor(dir)      Nav.move_cursor(self, dir) end
function TreeView:open_cursor_item()    Nav.open_cursor_item(self) end
function TreeView:collapse_or_go_to_parent()     Nav.collapse_or_go_to_parent(self) end
function TreeView:expand_or_go_to_first_child()  Nav.expand_or_go_to_first_child(self) end

function TreeView:update()
  local dest = self.visible and config.treeview_size or 0
  if self.init_size then
    self.size.x    = dest
    self.init_size = false
  else
    self:move_towards(self.size, "x", dest)
  end
  TreeView.super.update(self)
end

function TreeView:set_locked_size(axis, value)
  if axis == "x" then config.treeview_size = value end
end

local function status_badge(item, is_ro)
  if is_ro then return "RO", style.dim end
  return API.get_badge(item)
end

function TreeView:draw()
  self:draw_background(style.background2)

  local icon_width = style.icon_font:get_width("D")
  local spacing    = style.font:get_width(" ") * 2

  local doc = core.active_view.doc
  local active_filename = doc and system.absolute_path(doc.filename or "")

  for item, x, y, w, h in self:each_item() do
    local color = item.git_ignored and style.dim or style.text

    if item.abs_filename == active_filename then color = style.accent end

    if self.selected[item.abs_filename] then
      renderer.draw_rect(x, y, w, h, style.selection)
    end

    if item == self.cursor_item and core.active_view == self then
      renderer.draw_rect(x, y, w, h, style.line_highlight)
      renderer.draw_rect(x, y, w, math.ceil(SCALE), style.accent)
      renderer.draw_rect(x, y+h-math.ceil(SCALE), w, math.ceil(SCALE), style.accent)
    end

    if item == self.hovered_item then
      renderer.draw_rect(x, y, w, h, style.line_highlight)
      color = style.accent
    end

    local row_x = x + item.depth * style.padding.x + style.padding.x

    if item.type == "dir" then
      local icon1 = item.expanded and "-" or "+"
      local icon2 = item.expanded and "D" or "d"
      common.draw_text(style.icon_font, color, icon1, nil, row_x, y, 0, h)
      row_x = row_x + style.padding.x
      common.draw_text(style.icon_font, color, icon2, nil, row_x, y, 0, h)
      row_x = row_x + icon_width
    else
      row_x = row_x + style.padding.x
      common.draw_text(style.icon_font, color, "f", nil, row_x, y, 0, h)
      row_x = row_x + icon_width
    end

    row_x = row_x + spacing

    local is_ro = item.type == "file" and Build.is_file_readonly(RO.store, item.abs_filename)
    local badge, bcolor = status_badge(item, is_ro)

    -- â”€â”€ right-aligned badge â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    -- The badge floats to the right edge; the filename is clipped before it.
    local badge_w    = 0
    local badge_x    = 0
    local badge_marg = style.padding.x

    if badge then
      badge_w = style.font:get_width(badge)
      badge_x = x + w - style.padding.x - badge_w
    end

    -- Name draws in whatever space remains before the badge
    local name_max_w = w - (row_x - x) - style.padding.x
                       - (badge and (badge_w + badge_marg) or 0)
    local display_name = Build.truncate_name(style.font, item.name, name_max_w)
    common.draw_text(style.font, color, display_name, nil, row_x, y, 0, h)

    -- Draw the badge on the right with a very subtle dim background dot
    if badge then
      -- Tiny bg swatch so the badge letter pops against the tree background
      local bg_pad = 3
      local bg_col = { 0, 0, 0, 50 }
      renderer.draw_rect(badge_x - bg_pad, y + 2, badge_w + bg_pad * 2, h - 4, bg_col)
      common.draw_text(style.font, bcolor, badge, nil, badge_x, y, 0, h)
    end
  end
end

local view = TreeView()
API.set_view(view)
local node = core.root_view:get_active_node()
node:split("left", view, true)

Doc._after_save[#Doc._after_save + 1] = Ops.request_project_rescan

-- The commands live in commands.lua; this module is only the view.
-- init.lua owns the instance and registers them.
return view
