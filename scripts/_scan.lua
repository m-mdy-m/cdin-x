-- Shared filesystem helper for cdin-x development scripts.
local M = {}

local SEP = package.config:sub(1, 1)

local function shell_quote(path)
  if SEP == "\\" then
    return '"' .. path:gsub('"', '""') .. '"'
  end
  return "'" .. path:gsub("'", "'\\''") .. "'"
end

function M.manifest_paths()
  local command
  if SEP == "\\" then
    command = 'powershell -NoProfile -Command "Get-ChildItem -Path X -Recurse -Filter manifest.lua -File | ForEach-Object { $_.FullName }"'
  else
    command = "find " .. shell_quote("X") .. " -type f -name manifest.lua -print"
  end

  local pipe = io.popen(command)
  if not pipe then return {} end
  local result = {}
  for line in pipe:lines() do
    if line ~= "" then result[#result + 1] = line end
  end
  pipe:close()
  table.sort(result)
  return result
end

function M.read_manifest(path)
  local ok, meta = pcall(dofile, path)
  if ok and type(meta) == "table" then return meta end
  return nil
end

function M.dirname(path)
  return path:match("^(.*)[/\\][^/\\]+$")
end

function M.basename(path)
  return path:match("([^/\\]+)[/\\]?$" )
end

function M.category_from_manifest(path)
  local parent = M.dirname(path)
  local category = parent and parent:match("X[/\\]([^/\\]+)[/\\][^/\\]+$")
  return category or "unknown"
end

function M.exists(path)
  local f = io.open(path, "rb")
  if f then f:close(); return true end
  return false
end

function M.list_dir(path)
  local results = {}
  local handle = io.popen('ls "' .. path .. '" 2>/dev/null')
  if not handle then return results end
  for line in handle:lines() do
    local full = path .. "/" .. line
    local attr = io.popen('stat -c "%F" "' .. full .. '" 2>/dev/null'):read("*a"):gsub("%s+", "")
    table.insert(results, { name = line, type = attr == "directory" and "dir" or "file" })
  end
  handle:close()
  return results
end

-- Recursively list every regular file under `dir`. Returned paths are
-- relative to repo root (forward slashes), NOT relative to `dir` — so
-- they can be used directly as URL suffixes onto a
-- raw.githubusercontent.com/<owner>/<repo>/<ref>/ prefix. `dir` itself
-- is expected to already be a repo-root-relative path (e.g.
-- "X/core/treeview" or "core"), matching how manifest_paths() and the
-- other scan helpers address things — that's what makes the result
-- repo-root-relative without a separate prefix argument.
--
-- Used to freeze each plugin's/theme's/core's file set into the
-- generated manifest, so installers can fetch files individually
-- (curl per file) without ever needing a directory listing API call.
function M.list_files_recursive(dir)
  local command
  if SEP == "\\" then
    command = 'powershell -NoProfile -Command "Get-ChildItem -Path '
      .. dir .. ' -Recurse -File | ForEach-Object { $_.FullName }"'
  else
    command = "find " .. shell_quote(dir) .. " -type f -print"
  end

  local pipe = io.popen(command)
  if not pipe then return {} end
  local results = {}
  for line in pipe:lines() do
    if line ~= "" then
      results[#results + 1] = (line:gsub("\\", "/"))
    end
  end
  pipe:close()
  table.sort(results)
  return results
end

return M
