local M = {}
M.IS_WIN = PATHSEP == "\\"

function M.version_parts(v)
  local t = {}
  for n in (v or ""):gmatch("%d+") do t[#t + 1] = tonumber(n) end
  return t
end

function M.version_gt(a, b)
  local pa, pb = M.version_parts(a), M.version_parts(b)
  for i = 1, math.max(#pa, #pb) do
    local x, y = pa[i] or 0, pb[i] or 0
    if x ~= y then return x > y end
  end
  return false
end

function M.current_version()
  return (VERSION or "0.0.0"):match("(%d+%.%d+%.%d+[%-%w%.]*)") or "0.0.0"
end

return M
