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

return M
