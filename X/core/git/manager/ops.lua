local FindGit = require "X.core.git.manager.find-git"
local Utils = require "X.core.git.manager.utils"
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
-- Fetching the cdin-x registry is a git operation, so it belongs here rather
-- than in core. core/manager/registry.lua only knows a syncer may exist; the
-- git extension registers one (see api.lua's M.register).

local function quote(s)
  s = tostring(s)
  if Utils.IS_WIN then
    return '"' .. s:gsub('"', '\\"') .. '"'
  end
  return "'" .. s:gsub("'", "'\\''") .. "'"
end

local function succeeded(a, b, c)
  if a == true then return true end
  if type(a) == "number" then return a == 0 end
  if type(c) == "number" then return c == 0 end
  return false
end

local function run(cmd)
  local git = M.exe()
  if not git then return false, "git executable not found" end
  local a, b, c = os.execute(cmd)
  if succeeded(a, b, c) then return true end
  return false, "git command failed: " .. cmd
end

-- root is the registry's X/ directory; its parent is the git checkout.
-- `root`/.. must be derived with a separator-safe join because a bare ".."
-- after a trailing separator is a no-op on some platforms.
local function parent_of(root)
  return root:sub(1, -2)
end

-- Fetches (clone or pull) the registry into place. Called by core through the
-- syncer hook; returns true on success, or false plus a reason.
function M.sync_registry(root, url)
  local git = M.exe()
  if not git then return false, "git executable not found" end

  local checkout = parent_of(root)
  if Utils.IS_WIN then checkout = checkout:gsub("/", "\\") end

  if M.popen(git .. ' -C "' .. checkout .. '" rev-parse --git-dir 2>/dev/null') then
    return run(git .. ' -C "' .. checkout .. '" pull --ff-only')
  end

  local parent = checkout:match("^(.*)[/\\][^/\\]+[/\\][^/\\]+$") or checkout
  if Utils.IS_WIN then parent = parent:gsub("/", "\\") end
  return run(git .. " clone --depth 1 " .. quote(url) .. " " .. quote(checkout))
end

return M
