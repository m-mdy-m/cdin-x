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

return M
