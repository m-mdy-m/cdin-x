-- CDIN-X Plugin Manager panel.
local core    = require "core"
local common  = require "core.utils.common"
local command = require "core.input.command"
local config  = require "core.config"
local keymap  = require "core.input.keymap"
local style   = require "core.style"
local View    = require "core.views.view"
local Manager = require "core.x.manager"
local Command = require "core.x.command"

config.pluginmanager_size = 260 * SCALE

local CATEGORY_NAMES = {
  core = "CORE", languages = "LANGUAGES", lsp = "LSP", formatters = "FORMATTERS",
  git = "GIT", debug = "DEBUG", ui = "UI", utils = "UTILS",
  optional = "OPTIONAL", themes = "THEMES",
}
local CATEGORY_ORDER = {
  "core", "languages", "lsp", "formatters", "git", "debug", "ui", "utils", "optional", "themes",
}

local PluginManagerView = View:extend()

function PluginManagerView:new()
  PluginManagerView.super.new(self)
  self.scrollable   = true
  self.visible      = false
  self.init_size    = true
  self.cursor_row   = 1
  self.hovered_row  = nil
  self._rows        = {}
  self._rows_dirty  = true
end

function PluginManagerView:get_name() return "Plugins" end

function PluginManagerView:get_item_height()
  return style.font:get_height() + style.padding.y
end

-- Flattens Manager's catalog into an ordered row list: one header row
-- per non-empty category, one row per extension in that category. Rebuilt
-- on demand (see :invalidate / :refresh) rather than every frame.
function PluginManagerView:_rebuild_rows()
  Manager.scan()
  local plugins = Manager.list()

  local by_category, seen = {}, {}
  for _, plugin in pairs(plugins) do
    local cat = plugin.category or "other"
    by_category[cat] = by_category[cat] or {}
    table.insert(by_category[cat], plugin)
  end

  local ordered_categories = {}
  for _, cat in ipairs(CATEGORY_ORDER) do
    if by_category[cat] then
      ordered_categories[#ordered_categories + 1] = cat
      seen[cat] = true
    end
  end
  local extra = {}
  for cat in pairs(by_category) do
    if not seen[cat] then extra[#extra + 1] = cat end
  end
  table.sort(extra)
  for _, cat in ipairs(extra) do ordered_categories[#ordered_categories + 1] = cat end

  local rows = {}
  for _, cat in ipairs(ordered_categories) do
    local group = by_category[cat]
    table.sort(group, function(a, b) return a.name < b.name end)
    rows[#rows + 1] = { kind = "header", label = CATEGORY_NAMES[cat] or cat:upper() }
    for _, plugin in ipairs(group) do
      rows[#rows + 1] = { kind = "plugin", plugin = plugin }
    end
  end

  self._rows = rows
  self._rows_dirty = false

  -- Keep the cursor on a selectable row after a rebuild (e.g. after an
  -- install/uninstall changes which rows exist).
  if not self:_row_selectable(self.cursor_row) then
    self.cursor_row = self:_next_selectable(1, 1) or 1
  end
end

function PluginManagerView:_ensure_rows()
  if self._rows_dirty then self:_rebuild_rows() end
  return self._rows
end

function PluginManagerView:invalidate()
  self._rows_dirty = true
  core.redraw = true
end

function PluginManagerView:_row_selectable(i)
  local row = self._rows[i]
  return row ~= nil and row.kind == "plugin"
end

function PluginManagerView:_next_selectable(from, dir)
  local i = from
  while i >= 1 and i <= #self._rows do
    if self:_row_selectable(i) then return i end
    i = i + dir
  end
  return nil
end

function PluginManagerView:move_cursor(dir)
  self:_ensure_rows()
  local i = self.cursor_row + dir
  local found = self:_next_selectable(i, dir)
  if not found then
    -- wrap
    found = dir > 0 and self:_next_selectable(1, 1) or self:_next_selectable(#self._rows, -1)
  end
  if found then
    self.cursor_row = found
    self:scroll_to_cursor()
    core.redraw = true
  end
end

function PluginManagerView:scroll_to_cursor()
  local h = self:get_item_height()
  local y = (self.cursor_row - 1) * h
  if y < self.scroll.to.y then
    self.scroll.to.y = y
  elseif y + h > self.scroll.to.y + self.size.y then
    self.scroll.to.y = y + h - self.size.y
  end
end

function PluginManagerView:get_cursor_plugin()
  local row = self._rows[self.cursor_row]
  return row and row.kind == "plugin" and row.plugin or nil
end

-- Status glyph + color for a row. This is the single place that decides
-- what the colored marker looks like, so the palette (command.lua) and
-- this panel never disagree about what "active" means.
--   essential/builtin -> dim "#" (locked, cannot be toggled)
--   installed+enabled -> green "x" (matches the request: active = green x)
--   installed+disabled -> dim "-"
--   available, not installed -> dim "."
local function status_marker(plugin)
  if plugin._source == "builtin" or plugin.essential then
    return "#", style.dim
  end
  local st = Manager.get_status(plugin.name)
  if st == "installed" then
    return "x", style.git_added or style.accent
  elseif st == "disabled" then
    return "-", style.dim
  end
  return ".", style.dim
end

function PluginManagerView:each_row()
  return coroutine.wrap(function()
    local rows = self:_ensure_rows()
    local ox, oy = self:get_content_offset()
    local y = oy + style.padding.y
    local w = self.size.x
    local h = self:get_item_height()
    for i, row in ipairs(rows) do
      coroutine.yield(i, row, ox, y, w, h)
      y = y + h
    end
  end)
end

function PluginManagerView:on_mouse_moved(px, py, ...)
  PluginManagerView.super.on_mouse_moved(self, px, py, ...)
  self.hovered_row = nil
  for i, row, x, y, w, h in self:each_row() do
    if row.kind == "plugin" and px > x and py > y and px <= x + w and py <= y + h then
      self.hovered_row = i
      break
    end
  end
  self.cursor = self.hovered_row and "hand" or "arrow"
end

function PluginManagerView:on_mouse_pressed(button, x, y, clicks)
  if PluginManagerView.super.on_mouse_pressed(self, button, x, y, clicks) then return true end
  if not self.hovered_row then return end
  self.cursor_row = self.hovered_row
  if button == "left" and clicks == 1 then
    command.perform("pluginmanager:toggle-cursor")
  end
end

function PluginManagerView:update()
  local dest = self.visible and config.pluginmanager_size or 0
  if self.init_size then
    self.size.x = dest
    self.init_size = false
  else
    self:move_towards(self.size, "x", dest)
  end
  PluginManagerView.super.update(self)
end

function PluginManagerView:set_locked_size(axis, value)
  if axis == "x" then config.pluginmanager_size = value end
end

function PluginManagerView:draw()
  self:draw_background(style.background2)

  local title_h = style.font:get_height() + style.padding.y * 2
  common.draw_text(style.font, style.accent, "Plugin Manager", nil,
    self.position.x + style.padding.x, self.position.y + style.padding.y, 0, title_h)
  common.draw_text(style.font, style.dim, "shift+m close  j/k move  space toggle  enter details", nil,
    self.position.x + style.padding.x, self.position.y + style.padding.y + style.font:get_height(), 0, title_h)
  renderer.draw_rect(self.position.x, self.position.y + title_h * 1.6,
    self.size.x, math.ceil(SCALE), style.divider)

  local y_shift = title_h * 1.6 + math.ceil(SCALE)
  local ox_unused, oy = self:get_content_offset()

  for i, row, x, y, w, h in self:each_row() do
    local ry = y + y_shift
    if ry + h >= self.position.y and ry <= self.position.y + self.size.y then
      if row.kind == "header" then
        common.draw_text(style.font, style.dim, "── " .. row.label .. " ──", nil,
          x + style.padding.x, ry, 0, h)
      else
        local plugin = row.plugin
        local is_cursor = (i == self.cursor_row) and core.active_view == self
        local is_hover  = (i == self.hovered_row)

        if is_cursor then
          renderer.draw_rect(x, ry, w, h, style.line_highlight)
          renderer.draw_rect(x, ry, math.ceil(2 * SCALE), h, style.accent)
        elseif is_hover then
          renderer.draw_rect(x, ry, w, h, style.line_highlight)
        end

        local marker, mcolor = status_marker(plugin)
        local marker_x = x + style.padding.x
        common.draw_text(style.font, mcolor, marker, nil, marker_x, ry, 0, h)

        local name_x = marker_x + style.font:get_width("x") + style.padding.x
        local name_color = (plugin._source == "builtin" or plugin.essential) and style.dim or style.text
        common.draw_text(style.font, name_color, plugin.name, nil, name_x, ry, 0, h)

        if plugin.version and plugin.version ~= "" then
          local ver_w = style.font:get_width(plugin.version)
          common.draw_text(style.font, style.dim, plugin.version, nil,
            x + w - style.padding.x - ver_w, ry, 0, h)
        end
      end
    end
  end
end

local view = PluginManagerView()
local node = core.root_view:get_active_node()
node:split("right", view, true)

command.add(nil, {
  ["pluginmanager:toggle"] = function()
    view.visible = not view.visible
    if view.visible then
      view:invalidate()
      core.set_active_view(view)
    end
  end,

  ["pluginmanager:open"] = function()
    view.visible = true
    view:invalidate()
    core.set_active_view(view)
  end,

  ["pluginmanager:close"] = function()
    view.visible = false
  end,

  ["pluginmanager:refresh"] = function()
    view:invalidate()
  end,
})

command.add(function() return core.active_view == view end, {
  ["pluginmanager:select-previous"] = function() view:move_cursor(-1) end,
  ["pluginmanager:select-next"]     = function() view:move_cursor(1) end,

  ["pluginmanager:toggle-cursor"] = function()
    local plugin = view:get_cursor_plugin()
    if not plugin then return end
    if plugin._source == "builtin" or plugin.essential then
      core.log("cdin-x: %s is essential and cannot be disabled", plugin.name)
      return
    end
    local st = Manager.get_status(plugin.name)
    local ok, err
    if st == "installed" then
      ok, err = Manager.disable(plugin.name)
    elseif st == "disabled" then
      ok, err = Manager.enable(plugin.name)
    else
      ok, err = Manager.install(plugin.name)
    end
    if not ok then core.error("cdin-x: %s", err) end
    view:invalidate()
  end,

  ["pluginmanager:uninstall-cursor"] = function()
    local plugin = view:get_cursor_plugin()
    if not plugin then return end
    if plugin._source == "builtin" or plugin.essential then
      core.log("cdin-x: %s is essential and cannot be removed", plugin.name)
      return
    end
    if Manager.get_status(plugin.name) ~= "installed" and Manager.get_status(plugin.name) ~= "disabled" then
      return
    end
    local ok, err = Manager.uninstall(plugin.name)
    if not ok then core.error("cdin-x: %s", err) else core.log("cdin-x: uninstalled %s", plugin.name) end
    view:invalidate()
  end,

  ["pluginmanager:open-details"] = function()
    local plugin = view:get_cursor_plugin()
    if not plugin then return end
    Command.show_details(plugin.name)
  end,

  ["pluginmanager:open-readme"] = function()
    local plugin = view:get_cursor_plugin()
    if not plugin then return end
    local ok, err = Manager.open_readme(plugin.name)
    if not ok then core.error("cdin-x: %s", err) end
  end,
})

-- Keymap bindings. These are the plain (non-vim-mode) bindings. When vim
-- mode is enabled, X/core/vim/vimode.lua intercepts "m"/"shift+m" itself
-- (before keymap.on_key_pressed even runs) and calls the exact same
-- pluginmanager:* commands — so behavior is identical either way, only
-- the interception point differs. This block is what makes shift+m work
-- at all when vim mode is off, and is what makes j/k/space/enter/u work
-- for mouse-and-arrow-key users regardless of vim mode.
keymap.add {
  ["shift+m"] = "pluginmanager:toggle",
}

keymap.add {
  ["j"]      = "pluginmanager:select-next",
  ["down"]   = "pluginmanager:select-next",
  ["k"]      = "pluginmanager:select-previous",
  ["up"]     = "pluginmanager:select-previous",
  ["space"]  = "pluginmanager:toggle-cursor",
  ["x"]      = "pluginmanager:toggle-cursor",
  ["return"] = "pluginmanager:open-details",
  ["u"]      = "pluginmanager:uninstall-cursor",
  ["r"]      = "pluginmanager:open-readme",
  ["ctrl+r"] = "pluginmanager:refresh",
  ["escape"] = "pluginmanager:close",
}

return { view = view }
