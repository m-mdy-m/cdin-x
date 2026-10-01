-- Every panel command, in one file, with its predicate.
local core    = require "core"
local common  = require "core.utils.common"
local config  = require "core.config"
local command = require "core.input.command"
local Manager = require "cdinx.manager"
local Command = require "cdinx.command"

local M = {}

local view = nil
function M.bind(panel_view)
  view = panel_view
end

local function is_active()
  return view ~= nil and core.active_view == view
end

-- Browsing: the panel has focus and no search is being typed.
function M.browsing()
  return is_active() and not view.searching
end

-- Searching: the panel has focus and every key belongs to the query.
function M.searching()
  return is_active() and view.searching
end

local function current()
  local entry = view and view:entry_at_cursor()
  if not entry then
    core.log("extensions: nothing selected")
  end
  return entry
end

local function report(ok, err)
  if ok then return end
  core.error("extensions: %s", tostring(err))
end

-- ── the lifecycle of the panel itself ────────────────────────────────────

local function set_visible(visible)
  local was_active = core.active_view == view
  view.visible = visible
  if visible then
    view:invalidate()
    core.set_active_view(view)
    M.bootstrap_catalog()
  else
    -- Closing while focused has to hand focus back, or the next keystroke
    -- goes to a panel that is no longer on screen.
    view.searching = false
    view.query = ""
    view:invalidate()
    if was_active and core.last_active_view then
      core.set_active_view(core.last_active_view)
    end
  end
  core.redraw = true
end

M.set_visible = set_visible

function M.toggle()
  set_visible(not view.visible)
end

function M.resize(dir)
  local node = core.root_view:get_active_node()
  local parent = node and node:get_parent_node(core.root_view.root_node)
  local width = view.target_width or config.pluginmanager_size
  -- The panel owns a locked split, so its width is a pane width, and the
  -- pane is the ceiling: wider than that and it pushes the document off the
  -- window rather than showing more of a list.
  local ceiling = parent and math.max(parent.size.x - 200 * SCALE,
    config.pluginmanager_min) or width
  view.target_width = common.clamp(width + dir * 60 * SCALE,
    config.pluginmanager_min, ceiling)
  core.redraw = true
end

-- ── actions on the selected extension ────────────────────────────────────

function M.toggle_cursor()
  local entry = current()
  if not entry then return end
  if entry.locked then
    core.log("extensions: %s is part of the editor and is always on", entry.name)
    return
  end

  local ok, err
  if entry.status == "installed" then
    ok, err = Manager.disable(entry.name)
    if ok then core.log("extensions: disabled %s", entry.name) end
  elseif entry.status == "disabled" then
    ok, err = Manager.enable(entry.name)
    if ok then core.log("extensions: enabled %s", entry.name) end
  else
    ok, err = Manager.install(entry.name)
    if ok then core.log("extensions: installed %s", entry.name) end
  end
  report(ok, err)
  view:invalidate()
end

function M.install_cursor()
  local entry = current()
  if not entry then return end
  if entry.locked then
    core.log("extensions: %s ships with the editor", entry.name)
    return
  end
  local ok, err = Manager.install(entry.name)
  view:invalidate()
  if not ok then report(ok, err) return end
  core.log("extensions: installed %s", entry.name)
end

function M.uninstall_cursor()
  local entry = current()
  if not entry then return end
  if entry.locked then
    core.log("extensions: %s is part of the editor and cannot be removed",
      entry.name)
    return
  end
  if entry.status ~= "installed" and entry.status ~= "disabled" then
    core.log("extensions: %s is not installed", entry.name)
    return
  end
  local ok, err = Manager.uninstall(entry.name)
  if not ok then report(ok, err) return end
  core.log("extensions: removed %s", entry.name)
  view:invalidate()
end

function M.details()
  local entry = current()
  if entry then Command.show_details(entry.name) end
end

function M.readme()
  local entry = current()
  if not entry then return end
  local ok, err = Manager.open_readme(entry.name)
  if not ok then report(ok, err) end
end

-- Rescanning reads what is on disk. Updating the catalog is a download of
-- one file; ctrl+r does that.
function M.refresh()
  Manager.scan()
  view:invalidate()
  view:_ensure_rows()
  core.log("extensions: %d listed", view.total)
end

function M.catalog_status()
  local roots = Manager.roots()
  local state, message = Manager.catalog_state()
  local counts = view.counts or {}

  core.log("extensions: %d listed — %d in editor, %d installed, %d available",
    view.total, counts.editor or 0, counts.installed or 0, counts.available or 0)
  core.log("  catalog   : %s (%s)", roots.registry_dir,
    roots.registry and "on disk" or "not downloaded")
  core.log("  download  : %s%s", state, message and (" - " .. message) or "")
  core.log("  installed : %s", roots.installed and "present" or "nothing installed yet")
end

function M.update_catalog()
  local started, err = Manager.fetch_catalog(function(ok, ferr)
    if ok then
      core.log("extensions: catalog updated")
    else
      core.error("extensions: catalog download failed: %s", tostring(ferr))
    end
    view:invalidate()
  end)
  if started then
    core.log("extensions: downloading the catalog...")
  else
    core.error("extensions: %s", tostring(err))
  end
  view:invalidate()
end

function M.bootstrap_catalog()
  if Manager.roots().registry then return end
  if Manager.catalog_state() ~= "idle" then return end
  M.update_catalog()
end

-- ── search ───────────────────────────────────────────────────────────────

function M.search()
  view.searching = true
  core.redraw = true
end

function M.search_stop()
  view.searching = false
  core.redraw = true
end

function M.search_submit()
  view:search_submit()
end

function M.search_delete()
  view:search_delete()
end

function M.search_clear()
  view:search_clear()
end

-- ── registration ─────────────────────────────────────────────────────────
local PERSISTENT = {
  ["pluginmanager:toggle"] = "toggle",
  ["pluginmanager:open"]   = function() set_visible(true) end,
  ["pluginmanager:close"]  = function() set_visible(false) end,
}

local BROWSING = {
  ["pluginmanager:select-previous"]  = function() view:move_cursor(-1) end,
  ["pluginmanager:select-next"]      = function() view:move_cursor(1) end,
  ["pluginmanager:activate-cursor"]  = "toggle_cursor",
  ["pluginmanager:toggle-cursor"]    = "toggle_cursor",
  ["pluginmanager:install-cursor"]   = "install_cursor",
  ["pluginmanager:uninstall-cursor"] = "uninstall_cursor",
  ["pluginmanager:open-details"]     = "details",
  ["pluginmanager:open-readme"]      = "readme",
  ["pluginmanager:refresh"]          = "refresh",
  ["pluginmanager:catalog-status"]   = "catalog_status",
  ["pluginmanager:update-catalog"]   = "update_catalog",
  ["pluginmanager:search"]           = "search",
  ["pluginmanager:search-clear"]     = "search_clear",
  ["pluginmanager:narrow"]           = function() M.resize(-1) end,
  ["pluginmanager:widen"]            = function() M.resize(1) end,
}

local SEARCHING = {
  ["pluginmanager:search-stop"]   = "search_stop",
  ["pluginmanager:search-submit"] = "search_submit",
  ["pluginmanager:search-delete"] = "search_delete",
}

local function resolve(map)
  local out = {}
  for name, fn in pairs(map) do
    local resolved = fn
    if type(fn) == "string" then
      resolved = M[fn]
      assert(resolved, "panel command " .. name .. " names a function that does not exist: " .. fn)
    end
    out[name] = resolved
  end
  return out
end

function M.register()
  command.add(nil, resolve(PERSISTENT))
  command.add(M.browsing, resolve(BROWSING))
  command.add(M.searching, resolve(SEARCHING))
end

function M.unregister()
  local names = { "pluginmanager:toggle", "pluginmanager:open",
    "pluginmanager:close", "pluginmanager:menu" }
  for name in pairs(BROWSING) do names[#names + 1] = name end
  for name in pairs(SEARCHING) do names[#names + 1] = name end
  command.remove(names)
end

return M
