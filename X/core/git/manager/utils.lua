local M = {}
M.IS_WIN = PATHSEP == "\\"

function M.normalize_path(path)
  if M.IS_WIN then
    path = path:gsub("^/(%a)/", function(d) return d:upper() .. ":\\" end)
    path = path:gsub("/", "\\")
  end
  return path
end

function M.project_dir()
  local core = rawget(_G, "core")
  return (core and core.project_dir) or system.absolute_path(".") or "."
end

return M
