local common = require "core.utils.common"
local preboot = require "core.preboot"
local M = {}

function M.path()
  return preboot.path()
end

function M.load(core)
  return core._boot_session or preboot.read()
end

function M.save(core, session)
  local path = M.path()
  common.ensure_dir(path)
  local lines = { "return {" }

  lines[#lines + 1] = "  recent_files = {"
  for _, entry in ipairs(session.recent_files or {}) do
    local safe = entry:gsub("\\", "\\\\"):gsub('"', '\\"')
    lines[#lines + 1] = '    "' .. safe .. '",'
  end
  lines[#lines + 1] = "  },"

  lines[#lines + 1] = "  recent_dirs = {"
  for _, entry in ipairs(session.recent_dirs or {}) do
    local safe = entry:gsub("\\", "\\\\"):gsub('"', '\\"')
    lines[#lines + 1] = '    "' .. safe .. '",'
  end
  lines[#lines + 1] = "  },"

  if session.last_dir then
    local safe = session.last_dir:gsub("\\", "\\\\"):gsub('"', '\\"')
    lines[#lines + 1] = '  last_dir = "' .. safe .. '",'
  end
  if session.theme then
    local safe = session.theme:gsub("\\", "\\\\"):gsub('"', '\\"')
    lines[#lines + 1] = '  theme = "' .. safe .. '",'
  end
  lines[#lines + 1] = "}"

  local fp, err = io.open(path, "w")
  if not fp then
    core.error("session: cannot write %s — %s", path, err)
    return false
  end
  fp:write(table.concat(lines, "\n") .. "\n")
  fp:close()
  return true
end

function M.file_exists(path)
  local info = system.get_file_info(path)
  return info ~= nil and info.type == "file"
end

function M.dir_exists(path)
  local info = system.get_file_info(path)
  return info ~= nil and info.type == "dir"
end

function M.push_recent_dir(session, config, dirpath)
  if not dirpath then return end
  local abs = system.absolute_path(dirpath) or dirpath
  for i, value in ipairs(session.recent_dirs or {}) do
    if value == abs then table.remove(session.recent_dirs, i); break end
  end
  session.recent_dirs = session.recent_dirs or {}
  table.insert(session.recent_dirs, 1, abs)
  while #session.recent_dirs > config.session_max_recent do table.remove(session.recent_dirs) end
end

function M.set_last_dir(session, dirpath)
  if not dirpath then return end
  session.last_dir = system.absolute_path(dirpath) or dirpath
end

function M.push_recent_file(session, config, filename)
  if not filename then return end
  local abs = system.absolute_path(filename) or filename
  session.recent_files = session.recent_files or {}
  for i, value in ipairs(session.recent_files) do
    if value == abs then table.remove(session.recent_files, i); break end
  end
  table.insert(session.recent_files, 1, abs)
  while #session.recent_files > config.session_max_recent do table.remove(session.recent_files) end

  local dir = abs:match("^(.+)[\\/][^\\/]+$")
  if dir then M.push_recent_dir(session, config, dir) end
end

return M
