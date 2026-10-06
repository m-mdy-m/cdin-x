local M = {}

function M.read(path)
  local ok, chunk = pcall(loadfile, path)
  if not ok or not chunk then return nil end
  local ok2, data = pcall(chunk)
  if not ok2 or type(data) ~= "table" then return nil end
  return data
end

function M.exists(path)
  local info = path and system.get_file_info(path)
  return info ~= nil and info.type == "file"
end

function M.normalize(data)
  data = type(data) == "table" and data or {}
  data.tabs = type(data.tabs) == "table" and data.tabs or {}
  data.active_index = tonumber(data.active_index) or 1
  return data
end

return M
