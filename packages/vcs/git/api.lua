-- Git/VCS support: process helpers, status polling, and the shell
-- recipes an integration can run.
--
-- This is the module consumers require. It is deliberately NOT the
-- plugin's init.lua: the extension manager loads init.lua with dofile(),
-- which produces a *different* table from the one require() hands out, so
-- a plugin whose init.lua is also its public API ends up with two
-- half-initialised copies. init.lua therefore holds only the manifest and
-- delegates here.
local core     = require "core"
local config   = require "core.config"
local exec     = require "git.exec"
local Ops      = require "git.manager.ops"
local status   = require "git.status"
local recipes  = require "git.recipes"

local M = {}

config.git_update_rate = config.git_update_rate or 2

-- process helpers
M.exe            = exec.exe
M.exe_cwd        = exec.exe_cwd
M.popen          = exec.popen
M.normalize_path = exec.normalize_path
M.IS_WIN         = exec.IS_WIN

-- status polling (is_ignored, refresh_ignored_now, the status table the
-- status bar reads, and the background thread)
M.status   = status

-- shell command strings. Named `recipes` rather than `commands` because
-- they are not cdin commands: nothing registers them, they are just text
-- to hand to vim.shell.run_in_buffer().
M.recipes  = recipes

-- ── core integration point ──────────────────────────────────────────────
-- core is runtime-only, so it knows nothing about git. It exposes
-- tiny generic hooks instead (see core.register_vcs_provider in
-- the host's project scanner and status view) and degrades to "no vcs info"
-- when no plugin registers one:
--   is_ignored(abs_path)     -> boolean
--   refresh_ignored_now()    -> nil, best-effort, pcall'd by the caller
--   status                   -> table the status bar reads for the
--                               branch / ahead / behind / dirty pill
--
-- The extension catalog is NOT fetched with git: cdinx downloads
-- X/manifest.lua and the files of the one extension being installed over
-- HTTPS (see cdinx/manager/fetch.lua). Nothing here clones cdin-x.
local registered = false

function M.register()
  if registered then return end

  if core.register_vcs_provider then
    core.register_vcs_provider({
      is_ignored          = status.is_ignored,
      refresh_ignored_now = status.refresh_ignored_now,
      status              = status,
    })
  end

  registered = true
end

function M.unregister()
  -- core keeps no list to remove from; drop our flag so a later enable
  -- registers again.
  registered = false
end

return M
