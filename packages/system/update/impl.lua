-- Check whether a newer cdin release is available, and badge the status bar
-- until the user dismisses it.
--
-- The badge wraps StatusView.get_items, so it keeps the original around and
-- puts it back on unregister — previously the wrapper restored itself once
-- dismissed, but every check stacked another one and nothing could undo them
-- on unload.
local core   = require "core"
local style  = require "core.style"
local Fetcher = require "update.manager.fetcher"
local Utils  = require "update.manager.utils"

local M = {}

M.badge_dismissed = false

local original_get_items = nil
local badge_installed = false

local function install_badge(latest)
  if badge_installed then return end
  local StatusView = require "core.views.statusview"
  original_get_items = StatusView.get_items

  StatusView.get_items = function(self)
    local left, right = original_get_items(self)
    if M.badge_dismissed then
      return left, right
    end
    table.insert(right, 1, style.text)
    table.insert(right, 2, string.format(" ↑ v%s available ", latest))
    table.insert(right, 3, style.dim)
    return left, right
  end

  badge_installed = true
end

local function remove_badge()
  if not badge_installed then return end
  local StatusView = require "core.views.statusview"
  StatusView.get_items = original_get_items
  original_get_items = nil
  badge_installed = false
end

M.install_badge = install_badge
M.remove_badge = remove_badge

function M.check()
  core.log("Checking for updates…")
  -- on a thread: the release check is a network round trip and must not
  -- block the frame loop
  core.add_thread(function()
    local latest = Fetcher.latest_tag()
    if not latest then
      core.log("autoupdate: could not reach GitHub.")
      return
    end
    local current = Utils.current_version()
    if Utils.version_gt(latest, current) then
      core.log("cdin v%s is available! https://github.com/m-mdy-m/cdin/releases/tag/v%s", latest, latest)
      install_badge(latest)
    else
      core.log("cdin is up to date (v%s).", current)
    end
  end)
end

function M.dismiss()
  M.badge_dismissed = true
  core.log("autoupdate: update badge dismissed.")
end

return M
