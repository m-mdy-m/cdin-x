local FindGit = require "git.manager.find-git"
local Utils = require "git.manager.utils"
local M = {}

function M.exe()
  return FindGit.find()
end

function M.exe_with_dir(dir)
  local git = M.exe()
  if not git then return false end
  if not dir or dir == "" then return git end
  if Utils.IS_WIN then dir = dir:gsub("/", "\\") end
  return git .. ' -C "' .. dir .. '"'
end

function M.popen(cmd)
  if system.popen then return system.popen(cmd:gsub("%s*2>[^%s\"]*", "")) end
  local full = Utils.IS_WIN and ('cmd.exe /C "' .. cmd .. '"') or (cmd .. " 2>/dev/null")
  local ok, fp = pcall(io.popen, full)
  if not ok or not fp then return nil end
  local out = fp:read("*a"); fp:close(); return out
end

-- ── extension-registry fetching ───────────────────────────────────────────
-- Nothing. Fetching the cdin-x registry is not a git operation.
--
-- This header and the three helpers under it were the git path: `quote` and
-- `succeeded` for `os.execute`, and `run` for the git commands themselves. They
-- were kept when 0.1.0 dropped git fetching because a removal is easy to undo and a
-- forgotten reference is not -- and then nothing referenced them again, so they sat
-- here as the only dead code in the package.
--
-- `os.execute` is also the reason to leave them gone. Its return shape is the one
-- genuinely unportable thing in this file: Lua 5.1 returns an exit code as the first
-- value, 5.2+ returns `true` or `nil` plus a string, and a Windows shell that
-- cannot find the program looks like a successful one. `succeeded` was three
-- branches of guesswork about that, and nothing that ships should.
--
-- The registry is downloaded over HTTPS by `cdinx/manager/fetch.lua`, one file plus
-- the files of the one extension being installed. git is not used to install
-- cdin-x extensions at all, and `Manager.set_registry_syncer` -- the hook this path
-- was supposed to fill -- has no callers either. That is a deliberate seam, not an
-- oversight: a third-party extension may want to provide a faster sync, and the
-- seam costs one comparison in `registry.refresh`.

return M
