-- Finding and opening files and folders.
--
-- Three commands that all do the same shape of thing — prompt through
-- core.command_view, take what the user accepted, act on it — and would
-- otherwise share nothing but a copy of the path-resolution code. They live
-- together so there is one resolution, one error vocabulary and one place
-- that knows how to offer a path as you type.
--
--   core:find-file   fuzzy-match the project's file list
--   core:open-file   type or complete a path
--   core:open-folder type or complete a directory
--
-- All three are optional. The runtime keeps the mechanisms they are built
-- on: core.project_files, core.command_view, and core.set_project_dir().
local M = {
  name = "finder",
  version = "0.1.0",
  description = "Find a file by name, open a file or folder by path",
  author = "cdin Team",
  license = "MIT",
  category = "core",
  type = "plugin",
  essential = false,
  dependencies = {},
  min_cdin_version = "0.5.0",
  tags = { "ui", "files" },
}

M.config = {}

local KEYS = {
  ["ctrl+p"]       = "core:find-file",
  ["ctrl+o"]       = "core:open-file",
  ["ctrl+shift+o"] = "core:open-folder",
}

local NAMES = { "core:find-file", "core:open-file", "core:open-folder" }

local loaded = false
local help_handle = nil

-- Trims what the user typed and rejects it if there is nothing left. The
-- suggestion functions hand back an empty string when nothing matches, and
-- "open the file at the empty path" is not a thing to attempt.
local function clean(text)
  if type(text) ~= "string" then return nil end
  local trimmed = text:match("^%s*(.-)%s*$")
  if trimmed == "" then return nil end
  return trimmed
end

-- Directory suggestions for core:open-folder.
--
-- core.fs.list, not system.list_dir. The two look alike and are not: list_dir
-- returns an array of names, so `entry.type` on one of its values is nil and
-- every directory is skipped — a prompt that silently offers nothing, with no
-- error anywhere. fs.list stats each entry and returns {name, type, size},
-- which is what tells a directory from a file. common.path_suggest, which the
-- other two commands use, reaches the same answer through
-- system.get_file_info per name.
local function suggest_dirs(text)
  local common = require "core.utils.common"
  local fs     = require "core.fs"

  -- Everything up to and including the last separator is the directory to
  -- list; the rest is what the user is still typing inside it. The trailing
  -- separator is kept for rebuilding the path, and trimmed for the list call,
  -- because fs.list appends its own separator and would produce "a//b".
  local base = text:match("^(.*[/\\])") or ""
  local listing_dir = base:gsub("[/\\]+$", "")
  if listing_dir == "" then listing_dir = "." end

  local res = {}
  for _, entry in ipairs(fs.list(listing_dir) or {}) do
    if entry.type == "dir" then
      res[#res + 1] = base .. entry.name .. PATHSEP
    end
  end
  return common.fuzzy_match(res, text)
end

local function register()
  local core    = require "core"
  local common  = require "core.utils.common"
  local command = require "core.input.command"
  local keymap  = require "core.input.keymap"

  local function open_doc(path)
    core.root_view:open_doc(core.open_doc(path))
  end

  command.add(nil, {
    ["core:find-file"] = function()
      core.command_view:enter("Open File From Project", function(text, item)
        local path = (item and item.text) or clean(text)
        if not path then return end
        core.try(open_doc, path)
      end, function(text)
        -- Read the live table: the project scanner rebuilds it in place as
        -- it walks, and a copy taken at open time would be stale.
        local files = {}
        for _, item in pairs(core.project_files) do
          if item.type == "file" then files[#files + 1] = item.filename end
        end
        return common.fuzzy_match(files, text)
      end)
    end,

    ["core:open-file"] = function()
      core.command_view:enter("Open File", function(text, item)
        local path = clean((item and item.text) or text)
        if not path then return end
        local abs = system.absolute_path(path)
        if not abs then core.error("Cannot resolve: %s", path); return end
        local info = system.get_file_info(abs)
        if not info or info.type ~= "file" then
          core.error("Not a file: %s", abs)
          return
        end
        core.try(open_doc, abs)
      end, common.path_suggest)
    end,

    ["core:open-folder"] = function()
      core.command_view:enter("Open Folder", function(text, item)
        local path = clean((item and item.text) or text)
        if not path then return end
        -- The runtime owns the transition: chdir, reset the file list,
        -- bump the revision. This only chooses the directory and reports why
        -- it could not be entered.
        local ok, err = core.set_project_dir(path)
        if not ok then core.error("%s", tostring(err)) end
      end, suggest_dirs)
    end,
  })

  keymap.add(KEYS)

  help_handle = core.register_help_shortcuts({
    { key = "ctrl+p",       desc = "Find file (fuzzy)", section = true },
    { key = "ctrl+o",       desc = "Open file…" },
    { key = "ctrl+shift+o", desc = "Open folder…" },
  })
end

local function unregister()
  require("core.input.keymap").remove(KEYS)
  require("core.input.command").remove(NAMES)
  if help_handle then
    require("core").unregister_help_shortcuts(help_handle)
    help_handle = nil
  end
end

function M.init(core, config)
  if loaded then return end
  loaded = true
  register()
end

function M.unload()
  if not loaded then return end
  unregister()
  loaded = false
end

return M
