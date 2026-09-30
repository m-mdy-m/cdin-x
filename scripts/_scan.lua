-- Shared filesystem helper for cdin-x development scripts.
local M = {}

local SEP = package.config:sub(1, 1)

local function shell_quote(path)
  if SEP == "\\" then
    return '"' .. path:gsub('"', '""') .. '"'
  end
  return "'" .. path:gsub("'", "'\\''") .. "'"
end

function M.plugin_entries()
  local entries = {}
  local seen_dirs = {}

  -- old format, separate manifest: X/<category>/<name>/manifest.lua
  local command
  if SEP == "\\" then
    command = 'powershell -NoProfile -Command "Get-ChildItem -Path X -Recurse -Filter manifest.lua -File | ForEach-Object { $_.FullName }"'
  else
    command = "find " .. shell_quote("X") .. " -type f -name manifest.lua -print"
  end
  local pipe = io.popen(command)
  if pipe then
    for line in pipe:lines() do
      if line ~= "" then
        local plugin_dir = M.dirname(line)
        local category = plugin_dir and plugin_dir:match("^X[/\\]([^/\\]+)[/\\]")
        local has_name_segment = plugin_dir and plugin_dir:match("^X[/\\][^/\\]+[/\\].+")
        if category and has_name_segment then
          local meta = M.read_manifest(line)
          if meta then
            entries[#entries + 1] = {
              path = line, meta = meta, category = meta.category or category,
              single_file = false, base = plugin_dir,
            }
            seen_dirs[plugin_dir] = true
          end
        end
      end
    end
    pipe:close()
  end
  local function scan_for_inlined_plugins(dir, category_name)
    for _, entry in ipairs(M.list_dir(dir) or {}) do
      if entry.type == "dir" and entry.name ~= ".git" then
        local sub_dir = dir .. "/" .. entry.name
        if not seen_dirs[sub_dir] then
          local init_path = sub_dir .. "/init.lua"
          if M.exists(init_path) then
            local ok, meta = pcall(dofile, init_path)
            if ok and type(meta) == "table" and type(meta.name) == "string" then
              entries[#entries + 1] = {
                path = init_path, meta = meta,
                category = meta.category or category_name,
                single_file = false, base = sub_dir,
              }
              seen_dirs[sub_dir] = true
            end
          else
            scan_for_inlined_plugins(sub_dir, category_name)
          end
        end
      end
    end
  end

  for _, category_entry in ipairs(M.list_dir("X") or {}) do
    if category_entry.type == "dir" and category_entry.name ~= ".git" then
      scan_for_inlined_plugins("X/" .. category_entry.name, category_entry.name)
    end
  end

  -- new format: X/<category>/<name>.lua (excluding the category's own
  -- generated "manifest.lua" index file, which lives at that same depth)
  for _, category_entry in ipairs(M.list_dir("X") or {}) do
    if category_entry.type == "dir" and category_entry.name ~= ".git" then
      local cat_dir = "X/" .. category_entry.name
      for _, entry in ipairs(M.list_dir(cat_dir) or {}) do
        if entry.type == "file" and entry.name ~= "manifest.lua" then
          local name = entry.name:match("^(.+)%.lua$")
          if name then
            local file_path = cat_dir .. "/" .. entry.name
            local ok, meta = pcall(dofile, file_path)
            if ok and type(meta) == "table" then
              entries[#entries + 1] = {
                path = file_path, meta = meta,
                category = meta.category or category_entry.name,
                single_file = true, base = cat_dir,
              }
            end
          end
        end
      end
    end
  end

  table.sort(entries, function(a, b) return a.path < b.path end)
  return entries
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

-- Is this path a directory?
function M.is_dir(path)
  if SEP == "\\" then
    local p = path:gsub("'", "''")
    local handle = io.popen('powershell -NoProfile -Command "if (Test-Path -LiteralPath \''
      .. p .. '\' -PathType Container) { \'yes\' }"')
    local out = handle and handle:read("*a") or ""
    if handle then handle:close() end
    return out:find("yes") ~= nil
  end
  local handle = io.popen('test -d "' .. path .. '" && echo yes')
  local out = handle and handle:read("*a") or ""
  if handle then handle:close() end
  return out:find("yes") ~= nil
end

-- Does this path exist at all, file or directory?
function M.exists(path)
  local f = io.open(path, "rb")
  if f then f:close(); return true end
  return M.is_dir(path)
end

-- List one directory as { name, type = "dir"|"file" }.
function M.list_dir(path)
  local results = {}
  local command
  if SEP == "\\" then
    local p = path:gsub("'", "''")
    command = 'powershell -NoProfile -Command "Get-ChildItem -LiteralPath \'' .. p ..
      '\' -Force | ForEach-Object { if ($_.PSIsContainer) { \'DIR \' + $_.Name } else { \'FILE \' + $_.Name } }"'
  else
    command = "ls -A " .. shell_quote(path) .. " 2>/dev/null"
  end

  local handle = io.popen(command)
  if not handle then return results end
  for line in handle:lines() do
    local kind, name = line:match("^(%u+)%s+(.+)$")
    if name then
      results[#results + 1] = { name = name, type = (kind == "DIR") and "dir" or "file" }
    end
  end
  handle:close()
  return results
end

function M.list_files_recursive(dir)
  local command, strip_prefix
  if SEP == "\\" then
    local cwd = (io.popen("cd"):read("*a") or ""):gsub("[\r\n]", "")
    strip_prefix = cwd:gsub("\\", "/"):gsub("/+$", "") .. "/"
    command = 'powershell -NoProfile -Command "Get-ChildItem -LiteralPath \''
      .. dir:gsub("'", "''") .. '\' -Recurse -File | ForEach-Object { $_.FullName }"'
  else
    command = "find " .. shell_quote(dir) .. " -type f -print"
  end

  local pipe = io.popen(command)
  if not pipe then return {} end
  local results = {}
  for line in pipe:lines() do
    if line ~= "" then
      local path = line:gsub("\\", "/")
      if strip_prefix and path:sub(1, #strip_prefix) == strip_prefix then
        path = path:sub(#strip_prefix + 1)
      end
      results[#results + 1] = path
    end
  end
  pipe:close()
  table.sort(results)
  return results
end

-- A theme is a directory holding theme.lua — the same layout the host's
-- theme registry uses (<root>/<name>/theme.lua), so a theme can be handed
-- straight to core.themes.add_root() without being copied or renamed.
function M.theme_entries()
  local entries = {}
  local themes_dir = "X/themes"
  if not M.exists(themes_dir) then return entries end
  for _, entry in ipairs(M.list_dir(themes_dir) or {}) do
    if entry.type == "dir" and entry.name ~= ".git" then
      local path = themes_dir .. "/" .. entry.name .. "/theme.lua"
      if M.exists(path) then
        local ok, data = pcall(dofile, path)
        if ok and type(data) == "table" then
          entries[#entries + 1] = {
            name = data.name or entry.name,
            path = path,
            base = themes_dir .. "/" .. entry.name,
            data = data,
          }
        end
      end
    end
  end
  table.sort(entries, function(a, b) return a.name < b.name end)
  return entries
end

return M
