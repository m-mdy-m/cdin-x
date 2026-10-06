local Host = require "cdinx.host"
local Util = {}

function Util.count(t)
  local n = 0
  for _ in pairs(t or {}) do n = n + 1 end
  return n
end

function Util.join(...)
  local values = {...}
  local out = values[1]
  for i = 2, #values do
    if out:sub(-1) ~= "/" and out:sub(-1) ~= "\\" then
      out = out .. Host.sep
    end
    out = out .. values[i]
  end
  return out
end

function Util.quote(s)
  s = tostring(s)
  if Host.sep == "\\" then
    return '"' .. s:gsub('"', '\\"') .. '"'
  end
  return "'" .. s:gsub("'", "'\\''") .. "'"
end

function Util.result_ok(a, b, c)
  if a == true then return true end
  if type(a) == "number" then return a == 0 end
  if type(c) == "number" then return c == 0 end
  return false
end

function Util.parent_dir(path)
  return Host.fs.dirname(path)
end

return Util
