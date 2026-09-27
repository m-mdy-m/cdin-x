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
        local category = plugin_dir and plugin_dir:match("X[/\\]([^/\\]+)[/\\][^/\\]+$")
        if category then
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

  -- old format, manifest inlined in init.lua: X/<category>/<name>/init.lua
  for _, category_entry in ipairs(M.list_dir("X") or {}) do
    if category_entry.type == "dir" and category_entry.name ~= ".git" then
      local cat_dir = "X/" .. category_entry.name
      for _, entry in ipairs(M.list_dir(cat_dir) or {}) do
        if entry.type == "dir" then
          local plugin_dir = cat_dir .. "/" .. entry.name
          if not seen_dirs[plugin_dir] then
            local init_path = plugin_dir .. "/init.lua"
            if M.exists(init_path) then
              local ok, meta = pcall(dofile, init_path)
              if ok and type(meta) == "table" and type(meta.name) == "string" then
                entries[#entries + 1] = {
                  path = init_path, meta = meta,
                  category = meta.category or category_entry.name,
                  single_file = false, base = plugin_dir,
                }
              end
            end
          end
        end
      end
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

function M.theme_entries()
  local entries = {}
  local themes_dir = "X/themes"
  if not M.exists(themes_dir) then return entries end
  for _, entry in ipairs(M.list_dir(themes_dir) or {}) do
    if entry.type == "file" then
      local name = entry.name:match("^(.+)%.lua$")
      if name then
        local path = themes_dir .. "/" .. entry.name
        local ok, data = pcall(dofile, path)
        if ok and type(data) == "table" then
          entries[#entries + 1] = { name = name, path = path, data = data }
        end
      end
    end
  end
  table.sort(entries, function(a, b) return a.name < b.name end)
  return entries
end

return M
