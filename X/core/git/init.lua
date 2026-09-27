-- git: VCS status/exec/commands, moved out of cdin core
-- (was data/core/git/{init,exec,status,commands}.lua).
--
-- data/core is runtime-only; a plain-text editor works with zero
-- knowledge of git, so this whole module now lives here as a plugin.
--
-- Two integration points on core stay in cdin (they are tiny, generic
-- hooks, not git-specific code):
--   core.register_vcs_provider(provider)  -- see project.lua / statusview.lua
--     provider.is_ignored(abs_path)        -> boolean
--     provider.refresh_ignored_now()       -> nil (best-effort, pcall'd by caller)
--     provider.status                      -> table read by statusview for the
--                                              branch/ahead/behind/dirty pill
-- If this plugin is never loaded, both call sites degrade to "no vcs info"
-- instead of erroring.

local core     = require "core"
local exec     = require "X.core.git.exec"
local status   = require "X.core.git.status"
local commands = require "X.core.git.commands"

local M = {}

M.exe            = exec.exe
M.exe_cwd        = exec.exe_cwd
M.popen          = exec.popen
M.normalize_path = exec.normalize_path
M.IS_WIN         = exec.IS_WIN
M.status         = status
M.commands       = commands

if core.register_vcs_provider then
  core.register_vcs_provider({
    is_ignored          = status.is_ignored,
    refresh_ignored_now = status.refresh_ignored_now,
    status               = status,
  })
end

return M
