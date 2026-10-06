-- Git status badges in the project file tree.
--
-- The treeview package knows nothing about git: it exposes a generic provider
-- registry (badge + refresh, see treeview/api.lua) and this fills it in. Nothing
-- in treeview mentions git, and nothing else in git mentions treeview — which is
-- exactly why this is a `with` entry rather than a package or a dependency.
--
-- `with` on `treeview`, declared by `git`. That single key is enough: the entry
-- is only ever offered while `git` itself is loaded, so `git` being up is implied
-- by the fact that we are running, and `treeview` is the only other party there
-- is to wait for. Two packages, one name in the table — which is the general
-- shape of the mechanism, not a special case of it.
--
-- Everything is required inside `enable`, so a user without treeview never builds
-- any of it, and git's status thread does not start for them.
local M = {}

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

local enabled = false

function M.enable()
  if enabled then return end
  enabled = true

  local core     = require "core"
  local style    = require "core.style"
  local git      = require "git.api"
  local treeview = require "treeview.api"

  treeview.register_badge_provider(PROVIDER_ID, function(item)
    local status = git.status.get_status(item)
    if not status then return nil end
    return ICON[status] or status, badge_color(style, status)
  end, 100)

  treeview.register_refresh_provider(PROVIDER_ID, git.status.refresh)
  core.add_thread(git.status.thread)
end

function M.disable()
  if not enabled then return end
  enabled = false
  local treeview = require "treeview.api"
  treeview.remove_badge_provider(PROVIDER_ID)
  treeview.remove_refresh_provider(PROVIDER_ID)
end

return M