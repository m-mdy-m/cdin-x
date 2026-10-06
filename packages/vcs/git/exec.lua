local Ops = require "git.manager.ops"
local Utils = require "git.manager.utils"

local M = {}
M.IS_WIN = Utils.IS_WIN
M.exe = Ops.exe
M.exe_with_dir = Ops.exe_with_dir
M.popen = Ops.popen
M.normalize_path = Utils.normalize_path

function M.exe_cwd()
  return Ops.exe_with_dir(Utils.project_dir())
end

return M
