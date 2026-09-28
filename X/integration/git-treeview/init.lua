-- Git status badges in the project file tree.
--
-- The treeview plugin knows nothing about git: it exposes a generic
-- provider registry (badge + refresh, see X/core/treeview/api.lua) and this
-- integration fills it in. Nothing in X/core/treeview mentions git, and
-- nothing in X/core/git mentions treeview.
--
-- The manifest is inline, and everything is required inside init(), so the
-- extension catalog can dofile() this file to read the manifest without
-- starting git's status thread for a plugin that may never be installed.
local M = {
  name = "git-treeview",
  version = "0.2.0",
  description = "Git status badges and refresh integration for Treeview",
  author = "cdin Team",
  license = "MIT",
  category = "integration",
  type = "plugin",
  essential = false,
  dependencies = { "git", "treeview" },
  min_cdin_version = "0.5.0",
  tags = { "git", "treeview", "integration" },
}

-- Single-letter git status -> badge glyph, and -> colour. Kept as data so
-- the mapping is readable and the style fallbacks stay in one place.
local ICON = {
  M = "M", A = "A", D = "D", R = "R", C = "C", U = "!", ["?"] = "?",
}

local STYLE_KEY = {
  M = "git_modified", A = "git_added", D = "git_deleted",
  U = "git_conflict", R = "git_renamed", C = "git_renamed",
  ["?"] = "git_untracked",
}

local FALLBACK = {
  M = { 0xb8, 0x9a, 0x50, 0xff },
  A = { 0x5a, 0x9a, 0x5a, 0xff },
  D = { 0xb8, 0x50, 0x50, 0xff },
  U = { 0xd0, 0x60, 0x40, 0xff },
}

local PROVIDER_ID = "git"

local function badge_color(style, status)
  local key = STYLE_KEY[status]
  if key and style[key] then return style[key] end
  return FALLBACK[status] or style.accent
end

local loaded = false

function M.init()
  if loaded then return end
  loaded = true

  local core     = require "core"
  local style    = require "core.style"
  local git      = require "X.core.git.api"
  local treeview = require "X.core.treeview.api"

  treeview.register_badge_provider(PROVIDER_ID, function(item)
    local status = git.status.get_status(item)
    if not status then return nil end
    return ICON[status] or status, badge_color(style, status)
  end, 100)

  treeview.register_refresh_provider(PROVIDER_ID, git.status.refresh)
  core.add_thread(git.status.thread)
end

function M.unload()
  if not loaded then return end
  local treeview = require "X.core.treeview.api"
  treeview.remove_badge_provider(PROVIDER_ID)
  treeview.remove_refresh_provider(PROVIDER_ID)
  loaded = false
end

return M
