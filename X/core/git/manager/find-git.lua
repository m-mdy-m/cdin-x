local M = {}
local cached = nil

function M.find()
  if PATHSEP ~= "\\" then return "git" end
  if cached ~= nil then return cached end

  local function popen_raw(cmd)
    if system.popen then return system.popen(cmd:gsub("%s*2>[^%s\"]*", "")) end
    local ok, fp = pcall(io.popen, cmd)
    if not ok or not fp then return nil end
    local out = fp:read("*a"); fp:close(); return out
  end

  local out = popen_raw('cmd.exe /C "where.exe git 2>NUL"')
  if out and out ~= "" then
    local preferred = out:match("([^\r\n]+\\cmd\\git%.exe)")
    local first = out:match("([^\r\n]+)")
    local found = preferred or first
    if found then
      found = found:gsub("^%s+", ""):gsub("%s+$", "")
      if found ~= "" then cached = '"' .. found .. '"'; return cached end
    end
  end

  local candidates = {
    "C:\\Program Files\\Git\\cmd\\git.exe",
    "C:\\Program Files (x86)\\Git\\cmd\\git.exe",
    os.getenv("LOCALAPPDATA") and (os.getenv("LOCALAPPDATA") .. "\\Programs\\Git\\cmd\\git.exe"),
    os.getenv("ProgramFiles") and (os.getenv("ProgramFiles") .. "\\Git\\cmd\\git.exe"),
    os.getenv("USERPROFILE") and (os.getenv("USERPROFILE") .. "\\scoop\\apps\\git\\current\\cmd\\git.exe"),
  }
  for _, path in ipairs(candidates) do
    if path then
      local f = io.open(path, "rb")
      if f then f:close(); cached = '"' .. path .. '"'; return cached end
    end
  end

  cached = false
  return false
end

return M
