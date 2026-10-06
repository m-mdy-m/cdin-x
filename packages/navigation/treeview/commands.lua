-- Treeview commands.
--
-- Extracted from treeview_impl.lua, which had all eighteen of them inline in
-- the middle of the view implementation. They live here now, registered and
-- unregistered as a unit, so the view module is only about drawing and
-- navigating.
--
-- Three groups:
--   * global     — work whether or not the tree has focus
--   * view-scoped— cursor movement and actions that need the tree focused
--   * keystroke  — one command whose only job is to give a single key a
--                  predicate, so a keystroke can yield to another view without
--                  the command behind it becoming unavailable
local core    = require "core"
local common  = require "core.utils.common"
local config  = require "core.config"
local command = require "core.input.command"

local Cache   = require "treeview.cache"
local API     = require "treeview.api"
local Ops     = require "treeview.tree.operations"
local RO      = require "treeview.readonly"

local M = {}

-- Rebuilt from the tree and the registered refresh providers (git badges
-- and friends) in one place, since every mutating command needs it.
local function refresh()
  Ops.refresh(M.view, Cache, RO.store, API.refresh_providers)
end

local function rescan()
  Ops.request_project_rescan()
end

-- Repoint any open document that was pointing at a renamed file.
local function repoint(old_abs, new_path)
  for _, doc in ipairs(core.docs) do
    if doc.filename and system.absolute_path(doc.filename) == old_abs then
      doc.filename = new_path
    end
  end
end

local GLOBAL = {
  ["treeview:toggle"] = function()
    M.view.visible = not M.view.visible
    if not M.view.visible and core.active_view == M.view then
      local back = core.last_active_view
      if back and back ~= M.view and core.root_view.root_node:get_node_for_view(back) then
        core.set_active_view(back)
      else
        local doc = core.active_docview()
        if doc then core.set_active_view(doc) end
      end
    elseif M.view.visible then
      command.perform("treeview:focus-and-refresh")
    end
  end,

  ["treeview:focus"] = function()
    M.view.visible = true
    core.set_active_view(M.view)
    M.view:ensure_cursor()
    M.view:scroll_to_cursor()
  end,

  ["treeview:focus-and-refresh"] = function()
    command.perform("treeview:focus")
    command.perform("treeview:refresh")
  end,

  ["treeview:refresh"] = function() refresh() end,

  ["treeview:toggle-hidden"] = function()
    config.show_hidden_files = not config.show_hidden_files
    -- "^$" matches nothing, i.e. stop skipping dotfiles
    config.ignore_files = config.show_hidden_files and "^$" or "^%."
    refresh()
  end,

  ["treeview:new-file"] = function()
    local dir = Ops.context_dir(M.view)
    local prefix = dir ~= "." and (dir .. PATHSEP) or ""
    core.command_view:enter("New File", function(text)
      if text == "" then return end
      local path = prefix .. text
      local fp = io.open(path, "r")
      if fp then
        fp:close()
        core.error('treeview: "%s" already exists', path)
        return
      end
      fp = io.open(path, "w")
      if not fp then core.error('treeview: could not create "%s"', path); return end
      fp:close()
      refresh()
      rescan()
      core.try(function() core.root_view:open_doc(core.open_doc(path)) end)
    end, function(text) return common.path_suggest(prefix .. text) end)
  end,

  ["treeview:new-directory"] = function()
    local dir = Ops.context_dir(M.view)
    local prefix = dir ~= "." and (dir .. PATHSEP) or ""
    core.command_view:enter("New Directory", function(text)
      if text == "" then return end
      local path = prefix .. text
      -- mkdir through the shell so parents are created too (-p / no error
      -- on an existing parent)
      local ok = os.execute(PATHSEP == "\\"
        and ('cmd /c mkdir "' .. path .. '" 2>NUL')
        or  ('mkdir -p "' .. path .. '"'))
      if not ok then core.error('treeview: could not create directory "%s"', path); return end
      refresh()
      rescan()
    end, function(text) return common.path_suggest(prefix .. text) end)
  end,

  ["treeview:rename"] = function()
    local items = Ops.selected_items(M.view)
    local item  = items[1]
    if not item then return end
    core.command_view:enter("Rename", function(text)
      if text == "" or text == item.name then return end
      local parent  = item.filename:match("^(.*)[\\/][^\\/]+$") or "."
      local new_path = parent ~= "." and (parent .. PATHSEP .. text) or text
      local ok, err = os.rename(item.filename, new_path)
      if not ok then
        core.error("treeview: rename failed: %s", err or "unknown")
        return
      end
      repoint(item.abs_filename, new_path)
      refresh()
      rescan()
    end, function() return {} end)
    core.command_view:set_text(item.name, true)
  end,

  ["treeview:delete"] = function()
    local items = Ops.selected_items(M.view)
    if #items == 0 then return end
    local names = {}
    for _, it in ipairs(items) do names[#names + 1] = it.name end
    local msg = (#items == 1)
      and string.format('Delete "%s"? This cannot be undone.', names[1])
      or  string.format("Delete %d items? This cannot be undone.\n%s",
            #items, table.concat(names, ", "))
    if not system.show_confirm_dialog("Delete", msg) then return end
    for _, item in ipairs(items) do
      if item.type == "dir" then
        os.execute(PATHSEP == "\\"
          and ('cmd /c rmdir /s /q "' .. item.filename .. '" 2>NUL')
          or  ('rm -rf "' .. item.filename .. '"'))
      else
        os.remove(item.filename)
      end
    end
    M.view.selected = {}
    refresh()
    rescan()
  end,
}

-- Only offered while the tree itself has focus.
local function when_focused()
  return core.active_view == M.view and M.view.visible
end

-- F2 is the log view's key. Its header advertises it for switching between the
-- editor's log and the native one, and `log:switch-source` is already scoped to
-- that view, so it declines everywhere else and wins on this stroke — but only
-- if something on this side of the stroke declines too. A stroke is a fallback
-- chain and `keymap.add` prepends, so an always-available command here would
-- take F2 in the log view as well and the header would be advertising a lie.
--
-- Same shape as the FOCUSED group below, and for the same reason: the `-key`
-- suffix is a command that exists to give one keystroke a predicate, leaving
-- the real command (`treeview:toggle`) available from the palette and from
-- every integration whatever view is active.
local function unless_log_view()
  local ok, LogView = pcall(require, "core.views.logview")
  if not ok or not LogView then return true end
  local view = core.active_view
  return not (view and view:is(LogView))
end

local KEYSTROKE = {
  ["treeview:toggle-key"] = function() command.perform("treeview:toggle") end,
}

local FOCUSED = {
  ["treeview:rename-key"]       = function() command.perform("treeview:rename") end,
  ["treeview:delete-key"]       = function() command.perform("treeview:delete") end,
  ["treeview:refresh-key"]      = function() command.perform("treeview:refresh") end,
  ["treeview:select-previous"]  = function() M.view:move_cursor(-1) end,
  ["treeview:select-next"]      = function() M.view:move_cursor(1) end,
  ["treeview:open-cursor-item"] = function() M.view:open_cursor_item() end,
  ["treeview:collapse-or-parent"]  = function() M.view:collapse_or_go_to_parent() end,
  ["treeview:expand-or-child"]     = function() M.view:expand_or_go_to_first_child() end,
}

local GLOBAL_NAMES, FOCUSED_NAMES, KEYSTROKE_NAMES = {}, {}, {}
for name in pairs(GLOBAL) do GLOBAL_NAMES[#GLOBAL_NAMES + 1] = name end
for name in pairs(FOCUSED) do FOCUSED_NAMES[#FOCUSED_NAMES + 1] = name end
for name in pairs(KEYSTROKE) do KEYSTROKE_NAMES[#KEYSTROKE_NAMES + 1] = name end
table.sort(GLOBAL_NAMES)
table.sort(FOCUSED_NAMES)
table.sort(KEYSTROKE_NAMES)

function M.register(view)
  M.view = view
  command.add(nil, GLOBAL, true)
  command.add(when_focused, FOCUSED, true)
  command.add(unless_log_view, KEYSTROKE, true)
end

function M.unregister()
  command.remove(KEYSTROKE_NAMES)
  command.remove(GLOBAL_NAMES)
  command.remove(FOCUSED_NAMES)
  M.view = nil
end

return M
