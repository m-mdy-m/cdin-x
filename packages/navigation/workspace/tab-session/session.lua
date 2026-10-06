local core   = require "core"
local config = require "core.config"
local common = require "core.utils.common"
local command = require "core.input.command"
local Loader = require "workspace.session.manager.session-loader"

if config.tab_session_restore == nil then config.tab_session_restore = false end

local IS_WIN = PATHSEP == "\\"

local function session_path()
  local base
  if IS_WIN then
    base = os.getenv("APPDATA") or os.getenv("USERPROFILE") or "."
    return base .. "\\cdin\\tab_session.lua"
  else
    base = os.getenv("XDG_DATA_HOME") or (os.getenv("HOME") .. "/.local/share")
    return base .. "/cdin/tab_session.lua"
  end
end

local ensure_dir = common.ensure_dir

local function collect_files(node, out)
  if not node then return end
  if node.type == "leaf" then
    for _, v in ipairs(node.views or {}) do
      if v.doc and v.doc.filename then
        table.insert(out, v.doc.filename)
      end
    end
  else
    collect_files(node.a, out)
    collect_files(node.b, out)
  end
end

-- ─── save ───────────────────────────────────────────────────────────────────

local function save()
  local M = require "workspace.tab.manager"

  local path = session_path()
  ensure_dir(path)

  local lines = { "return {" }
  lines[#lines+1] = "  active_index = " .. (M.get_index(M.active_id) or 1) .. ","
  lines[#lines+1] = "  tabs = {"

  for _, id in ipairs(M.tab_order) do
    local tab = M.tabs[id]
    if tab then
      local files = {}
      collect_files(tab.root_node, files)
      -- also check if active tab has unsaved files in current node
      if id == M.active_id then
        collect_files(require("workspace.tab.manager").tabs[id] and
          core.root_view.root_node or nil, files)
      end
      local safe_name = tab.name:gsub('"', '\\"')
      lines[#lines+1] = "    {"
      lines[#lines+1] = '      name = "' .. safe_name .. '",'
      lines[#lines+1] = "      pinned = " .. tostring(tab.pinned) .. ","
      lines[#lines+1] = "      files = {"
      for _, f in ipairs(files) do
        local sf = f:gsub("\\", "\\\\"):gsub('"', '\\"')
        lines[#lines+1] = '        "' .. sf .. '",'
      end
      lines[#lines+1] = "      },"
      lines[#lines+1] = "    },"
    end
  end

  lines[#lines+1] = "  },"
  lines[#lines+1] = "}"

  local fp, err = io.open(path, "w")
  if not fp then
    core.error("tab-session: cannot write %s — %s", path, err)
    return false
  end
  fp:write(table.concat(lines, "\n") .. "\n")
  fp:close()
  return true
end

-- ─── restore ────────────────────────────────────────────────────────────────

local function restore()
  if not config.tab_session_restore then return end

  local path = session_path()
  if not Loader.exists(path) then return end
  local data = Loader.normalize(Loader.read(path))

  local M = require "workspace.tab.manager"

  local tabs = data.tabs or {}
  if #tabs == 0 then return end

  for i, tdata in ipairs(tabs) do
    if i == 1 then
      -- first tab already exists (bootstrap created it)
      local existing = M.tabs[M.active_id]
      if existing then
        existing.name   = tdata.name or existing.name
        existing.pinned = tdata.pinned or false
      end
      for _, f in ipairs(tdata.files or {}) do
        if system.get_file_info(f) then
          core.try(function()
            core.root_view:open_doc(core.open_doc(f))
          end)
        end
      end
    else
      local id = M.create(tdata.name or ("Tab " .. i), false)
      local tab_obj = M.tabs[id]
      if tab_obj then
        tab_obj.pinned = tdata.pinned or false
      end
      -- We can't restore individual layouts without deep-copying Node trees,
      -- so we activate the tab, open files, then move on.
      M.activate(id)
      for _, f in ipairs(tdata.files or {}) do
        if system.get_file_info(f) then
          core.try(function()
            core.root_view:open_doc(core.open_doc(f))
          end)
        end
      end
    end
  end

  -- switch to the previously active tab
  local active_idx = data.active_index or 1
  local target_id  = M.tab_order[active_idx] or M.tab_order[1]
  if target_id then M.activate(target_id) end

  core.log("tab-session: restored %d tab(s)", #tabs)
end

-- ─── registration ───────────────────────────────────────────────────────────
-- register()/unregister(), not side effects at require time.
--
-- This file used to subscribe to session.on_quit, start the restore thread and
-- add its command the moment it was required, and returned a table with only
-- save/restore on it. tab-session's init.lua calls register() — which did not
-- exist — so the integration never loaded at all, and the error was swallowed
-- by the manager's pcall and logged as one line among many.
--
-- The seam is the convention every other integration follows: init.lua
-- requires this and calls register(), and unload() calls unregister(). A
-- require that registered things could not be undone, and `loaded` in
-- init.lua would have been a lie about what had happened.
local S = {}
S.save    = save
S.restore = restore

-- Held so unregister() can hand the exact function back to off_quit, and so a
-- second register() is a no-op rather than a duplicate subscription.
local quit_hook = nil
local restore_thread = nil

local function on_quit(force)
  core.log("workspace.tab-session: on_quit fired, force=%s", tostring(force))
  save()
end

function S.register()
  if quit_hook then return end

  -- `session` owns the single core.quit wrapper for the whole X layer, and
  -- tab-session declares it as a dependency, so on_quit is available by now.
  -- Subscribing through it rather than wrapping core.quit a second time is
  -- what keeps one wrapper with several listeners.
  local session = require "workspace.session.api"
  quit_hook = session.on_quit(on_quit)

  command.add(nil, {
    ["tab:session-save"] = function()
      if S.save() then core.log("tab-session: saved") end
    end,
  })

  -- Delayed, not immediate: the root view has to exist and the first tab has
  -- to be bootstrapped before there is anything to restore into.
  restore_thread = function()
    coroutine.yield(0.1)
    restore()
  end
  core.add_thread(restore_thread)
end

function S.unregister()
  if not quit_hook then return end

  require("workspace.session.api").off_quit(quit_hook)
  quit_hook = nil

  command.remove("tab:session-save")
  restore_thread = nil
end

return S