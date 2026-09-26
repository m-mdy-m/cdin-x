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

function M.is_file(path)
  local attr = io.popen('stat -c "%F" "' .. path .. '" 2>/dev/null')
  if not attr then return false end
  local kind = attr:read("*a"):gsub("%s+", "")
  attr:close()
  return kind == "regular file" or kind == "regularfile"
end

function M.is_dir(path)
  local attr = io.popen('stat -c "%F" "' .. path .. '" 2>/dev/null')
  if not attr then return false end
  local kind = attr:read("*a"):gsub("%s+", "")
  attr:close()
  return kind == "directory"
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

-- Discovers every plugin directly under X/<category>/, in any of the
-- three on-disk shapes the runtime (core/manager/catalog.lua) accepts:
--   <category>/<name>/manifest.lua + init.lua   (folder, split manifest)
--   <category>/<name>/init.lua only              (folder, merged manifest)
--   <category>/<name>.lua                         (single file)
-- Returns a list of { name, category, plugin_dir, meta } — meta is the
-- table returned by dofile'ing whichever file holds the manifest fields
-- for that plugin. plugin_dir is what list_files_recursive() should be
-- called with to freeze that plugin's file set.
function M.discover_plugins(x_root)
  local out = {}
  for _, category_entry in ipairs(M.list_dir(x_root)) do
    local category = category_entry.name
    if category_entry.type == "dir" and category ~= ".git" and category ~= "themes" then
      local cat_dir = x_root .. "/" .. category
      for _, entry in ipairs(M.list_dir(cat_dir)) do
        if entry.type == "dir" then
          local plugin_dir = cat_dir .. "/" .. entry.name
          local manifest_file = plugin_dir .. "/manifest.lua"
          local init_file = plugin_dir .. "/init.lua"
          local meta_file
          if M.is_file(manifest_file) then
            meta_file = manifest_file
          elseif M.is_file(init_file) then
            meta_file = init_file
          end
          if meta_file then
            local meta = M.read_manifest(meta_file)
            if meta and meta.name then
              out[#out + 1] = { name = meta.name, category = category, plugin_dir = plugin_dir, meta = meta }
            end
          end
        elseif entry.name ~= "manifest.lua" then
          local name = entry.name:match("^(.+)%.lua$")
          if name then
            local file_path = cat_dir .. "/" .. entry.name
            local meta = M.read_manifest(file_path)
            if meta and meta.name then
              out[#out + 1] = { name = meta.name, category = category, plugin_dir = file_path, meta = meta }
            end
          end
        end
      end
    end
  end
  return out
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