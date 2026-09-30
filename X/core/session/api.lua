-- Session state and operations: recent files, recent directories, the last
-- directory, and the chosen theme — persisted between runs.
--
-- This is the module consumers use (X.core.session is also set to it at
-- load time for the picker hooks). It is deliberately not the plugin's
-- init.lua: the extension manager loads init.lua with dofile(), producing
-- a different table from the one require() hands out, so a plugin whose
-- init.lua is also its public API ends up with two half-built copies.
--
-- Two extension seams live here, and they are the supported way for other
-- plugins to hook in:
--
--   on_quit(fn)   run fn(force) while cdin is quitting. session is
--                 essential, so it owns the single wrap of core.quit for
--                 the whole X layer; a plugin that needs to persist on
--                 quit (tab-session) appends here rather than wrapping
--                 core.quit itself. One wrapper, many listeners, no risk
--                 of a dropped call if a second wrapper has a bug.
--
--   set_theme(n)  record the active theme and save immediately, so a
--                 choice made mid-session survives a crash rather than
--                 only a clean exit. Called by
--                 X/integration/session/theme-switcher.
local core   = require "core"
local config = require "core.config"
local Doc    = require "core.doc"
local Sys    = require "X.core.session.manager.sys"

local M = {}

if config.session_max_recent  == nil then config.session_max_recent  = 10  end
if config.session_restore      == nil then config.session_restore      = false end
if config.session_save_on_quit == nil then config.session_save_on_quit = true end
if config.session_restore_dir  == nil then config.session_restore_dir  = true end
if config.session_restore_theme == nil then config.session_restore_theme = true end

local state = Sys.load(core)

local function file_exists(path) return Sys.file_exists(path) end
local function dir_exists(path)  return Sys.dir_exists(path)  end

-- ── recent lists ─────────────────────────────────────────────────────────
function M.push_recent_file(filename)
  Sys.push_recent_file(state, config, filename)
end

function M.push_recent_dir(dirpath)
  Sys.push_recent_dir(state, config, dirpath)
end

function M.set_last_dir(dirpath)
  Sys.set_last_dir(state, dirpath)
end

function M.get_recent_files()
  local out = {}
  for _, path in ipairs(state.recent_files or {}) do
    if file_exists(path) then out[#out + 1] = path end
  end
  return out
end

-- kept for callers that predate get_recent_files
M.get_recent = M.get_recent_files

function M.get_recent_dirs()
  local out = {}
  for _, path in ipairs(state.recent_dirs or {}) do
    if dir_exists(path) then out[#out + 1] = path end
  end
  return out
end

-- ── persistence ──────────────────────────────────────────────────────────
function M.save()
  for _, doc in ipairs(core.docs) do
    if doc.filename then M.push_recent_file(doc.filename) end
  end
  return Sys.save(core, state)
end

function M.clear()
  state.recent_files = {}
  state.recent_dirs  = {}
  state.last_dir     = nil
  state.theme        = nil
  return Sys.save(core, state)
end

function M.info()
  return #(state.recent_files or {}), #(state.recent_dirs or {}), Sys.path
end

function M.state()
  return state
end

-- ── actions ──────────────────────────────────────────────────────────────
function M.open(path)
  core.try(function()
    core.root_view:open_doc(core.open_doc(path))
  end)
end

function M.open_dir(path)
  local ok, err = pcall(system.chdir, path)
  if not ok then return false, err end
  core.project_dir = system.absolute_path(".") or path
  M.push_recent_dir(path)
  M.set_last_dir(path)
  pcall(function() require("core.project").request_rescan(core) end)
  return true
end

-- ── extension seam ───────────────────────────────────────────────────────
-- on_quit is the supported way for another plugin to persist state when
-- cdin exits. session is essential, so it owns the single wrap of
-- core.quit; a plugin that wrapped it as well would risk dropping the
-- call chain. See X/integration/tab-session for the only current user.
local _on_quit = {}

function M.on_quit(fn)
  _on_quit[#_on_quit + 1] = fn
  return fn
end

function M.off_quit(fn)
  for i, f in ipairs(_on_quit) do
    if f == fn then table.remove(_on_quit, i); return end
  end
end

-- Record the active theme and persist right away, so a theme chosen during
-- a session survives even if cdin does not exit cleanly. core.quit also
-- writes config.theme, but only on a normal exit. Called by
-- X/integration/session/theme-switcher.
function M.set_theme(name)
  if not name then return end
  state.theme = name
  Sys.save(core, state)
end

-- ── pickers ──────────────────────────────────────────────────────────────
local function picker(title, items, on_pick)
  if #items == 0 then
    core.log("session: no recent %s", title:lower())
    return
  end
  core.command_view:enter(title, function(_, item)
    if item and item.path then on_pick(item.path) end
  end, function(text)
    if text == "" then return items end
    local needle = text:lower()
    local res = {}
    for _, it in ipairs(items) do
      if it.text:lower():find(needle, 1, true)
        or (it.info and it.info:lower():find(needle, 1, true)) then
        res[#res + 1] = it
      end
    end
    return res
  end)
end

function M.open_recent_files_picker()
  local items = {}
  for i, path in ipairs(state.recent_files or {}) do
    if file_exists(path) then
      local dir = path:match("^(.+)[\\/][^\\/]+$") or ""
      local dir_label = ""
      if dir ~= "" then
        local last = dir:match("([^\\/]+)$") or dir
        dir_label = last .. "/"
      end
      items[#items + 1] = {
        text = path:match("[^\\/]+$") or path,
        info = dir_label, path = path, idx = i,
      }
    end
  end
  picker("Recent Files", items, M.open)
end

function M.open_recent_dirs_picker()
  local items = {}
  for i, path in ipairs(state.recent_dirs or {}) do
    if dir_exists(path) then
      items[#items + 1] = {
        text = (path:match("([^\\/]+)[\\/]?$") or path) .. "/",
        info = path:match("^(.+)[\\/][^\\/]+$") or "",
        path = path, idx = i,
      }
    end
  end
  picker("Recent Directories", items, function(path)
    local ok, err = M.open_dir(path)
    if ok then
      core.log("session: changed to %s", path)
    else
      core.error("session: cd failed: %s", tostring(err))
    end
  end)
end

-- ── load / unload ────────────────────────────────────────────────────────
local registered = false
local original_quit = nil
local installed_hooks = {}

local function install_doc_hooks()
  -- Register hooks rather than monkey-patching Doc.load / Doc.save, so a
  -- file's path is recorded wherever it was opened or written from.
  local after_load = function(doc)
    if doc.filename then M.push_recent_file(doc.filename) end
  end
  local after_save = function(doc)
    if doc.filename then M.push_recent_file(doc.filename) end
  end
  table.insert(Doc._after_load, after_load)
  table.insert(Doc._after_save, after_save)
  installed_hooks = { after_load, after_save }
end

local function remove_doc_hooks()
  for _, list in ipairs({ Doc._after_load, Doc._after_save }) do
    for i = #list, 1, -1 do
      for _, hook in ipairs(installed_hooks) do
        if list[i] == hook then table.remove(list, i); break end
      end
    end
  end
  installed_hooks = {}
end

function M.register()
  if registered then return end
  registered = true

  core.session = M

  install_doc_hooks()

  -- session is essential, so it owns the one wrap of core.quit for the
  -- whole X layer.
  original_quit = core.quit
  core.quit = function(force)
    if config.session_save_on_quit then
      for _, doc in ipairs(core.docs) do
        if doc.filename then M.push_recent_file(doc.filename) end
      end
      if core.project_dir then M.set_last_dir(core.project_dir) end
      if config.theme then state.theme = config.theme end
      Sys.save(core, state)
    end
    for _, fn in ipairs(_on_quit) do core.try(fn, force) end
    original_quit(force)
  end

  -- The directory and the theme are already restored synchronously by
  -- core.init() before the first frame. All that
  -- is left is optionally reopening the last file, which still has to wait
  -- for the views to exist — hence the thread. core.try already guards it,
  -- so a bad restore cannot block startup either way.
  core.add_thread(function()
    if not config.session_restore then return end
    local recent = state.recent_files
    local first  = recent and recent[1]
    if first and file_exists(first) then
      core.try(function() core.root_view:open_doc(core.open_doc(first)) end)
      core.log("session: restored %s", first)
    end
  end)

  if core.register_recent_provider then
    core.register_recent_provider(M)
  end

  if core.register_help_shortcuts then
    core.register_help_shortcuts({
      { key = "ctrl+shift+r", desc = "Recent files picker" },
      { key = "ctrl+shift+d", desc = "Recent dirs picker" },
    })
  end

  require("X.core.session.commands").register()
  require("X.core.session.keymap").register()
end

function M.unregister()
  if not registered then return end
  registered = false

  require("X.core.session.keymap").unregister()
  require("X.core.session.commands").unregister()

  remove_doc_hooks()
  if original_quit then core.quit = original_quit; original_quit = nil end
  core.session = nil
end

return M
