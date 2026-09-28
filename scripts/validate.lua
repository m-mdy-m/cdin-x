local scan = dofile("scripts/_scan.lua")

-- scan.exists handles files *and* directories; a read-based check would
-- report every category directory as missing.
local exists = scan.exists

local errors = {}
local root_files = {
  "README.md",
  "core/init.lua",
  "core/config.lua",
  "core/manifest.lua",
  "core/command.lua",
  "scripts/new-plugin.lua",
  "scripts/install.sh",
  "scripts/validate.lua",
}
for _, path in ipairs(root_files) do
  if not exists(path) then errors[#errors+1] = path .. " not found" end
end

if exists("fonts") then
  local required_fonts = { "font.ttf", "monospace.ttf", "icons.ttf" }
  for _, f in ipairs(required_fonts) do
    if not exists("fonts/" .. f) then
      errors[#errors+1] = "fonts/" .. f .. " not found (fonts/ exists but is incomplete)"
    end
  end
end

-- ── plugins ─────────────────────────────────────────────────────────────
local function is_theme(entry)
  return entry.meta.type == "theme" or entry.category == "themes"
end

local essential_found = 0
for _, entry in ipairs(scan.plugin_entries()) do
  if entry.meta.essential == true and not is_theme(entry) then
    essential_found = essential_found + 1
    if entry.single_file then
      if not (type(entry.meta.init) == "function" or type(entry.meta.unload) == "function") then
        errors[#errors+1] = entry.path .. ": essential single-file plugin has no init/unload"
      end
    else
      if not exists(entry.base .. "/init.lua") then errors[#errors+1] = entry.base .. "/init.lua not found" end
      if not exists(entry.base .. "/README.md") then errors[#errors+1] = entry.base .. "/README.md not found" end
    end
  end
end
if essential_found == 0 then
  errors[#errors+1] = "no essential = true extensions found under X/ — expected at least one (e.g. core runtime plugins)"
end

-- ── the dependency rule ─────────────────────────────────────────────────
local known = {}
for _, entry in ipairs(scan.plugin_entries()) do
  if entry.meta.name then known[entry.meta.name] = entry end
end

local function namespace_of(entry)
  return entry.meta.category or entry.category
end

local function module_prefix(entry)
  local p = entry.path:gsub("\\", "/")
  if entry.single_file then
    p = p:gsub("%.lua$", "")
  else
    p = p:gsub("/[^/]+%.lua$", "")
  end
  return (p:gsub("/", "."))
end

-- The plugin owning a required module: the longest matching prefix wins,
-- so X.core.vim.ex resolves to vim rather than to a shorter prefix.
local function owner_of(module_name)
  local best_name, best_len
  for name, entry in pairs(known) do
    local prefix = module_prefix(entry)
    if module_name == prefix or module_name:sub(1, #prefix + 1) == (prefix .. ".") then
      if not best_len or #prefix > best_len then
        best_name, best_len = name, #prefix
      end
    end
  end
  return best_name
end

local function x_requires(path)
  local f = io.open(path, "rb")
  if not f then return {} end
  local src = f:read("*a")
  f:close()
  local out, seen = {}, {}
  local function add(mod)
    if not seen[mod] then seen[mod] = true; out[#out + 1] = mod end
  end
  for mod in src:gmatch('require%s*%(?%s*"([Xx]%.[%w_%.%-]+)"') do add(mod) end
  for mod in src:gmatch("require%s*%(?%s*'([Xx]%.[%w_%.%-]+)'") do add(mod) end
  return out
end

-- directories once per plugin and made validation take minutes.
local listing_cache = {}
local function files_under(dir)
  local hit = listing_cache[dir]
  if not hit then
    hit = scan.list_files_recursive(dir)
    listing_cache[dir] = hit
  end
  return hit
end

for name, entry in pairs(known) do
  if not is_theme(entry) then
    local declared = {}
    for _, d in ipairs(entry.meta.dependencies or {}) do declared[d] = true end
    local files = entry.single_file and { entry.path } or files_under(entry.base)
    for _, f in ipairs(files) do
      for _, mod in ipairs(x_requires(f)) do
        local owner = owner_of(mod)
        if owner and owner ~= name then
          if not declared[owner] then
            errors[#errors+1] = string.format(
              "%s requires %s (owned by %q) without declaring it: %s", name, mod, owner, f)
          elseif namespace_of(entry) ~= "integration" then
            errors[#errors+1] = string.format(
              "%s is in %s/ and requires %s — cross-plugin wiring belongs in X/integration/: %s",
              name, namespace_of(entry), mod, f)
          end
        end
      end
    end
  end
end

-- Every declared dependency has to exist, or install order is undefined.
for name, entry in pairs(known) do
  for _, d in ipairs(entry.meta.dependencies or {}) do
    if not known[d] then
      errors[#errors+1] = string.format("%s declares dependency %q which is not in the tree", name, d)
    end
  end
end

local essential_theme_found = 0
if exists("X/themes") then
  for _, theme in ipairs(scan.theme_entries()) do
    if theme.data.essential == true then
      essential_theme_found = essential_theme_found + 1
    end
  end
else
  errors[#errors+1] = "X/themes/ not found"
end
if essential_theme_found == 0 then
  errors[#errors+1] = "no essential = true theme found under X/themes/ — expected exactly one built-in default"
elseif essential_theme_found > 1 then
  errors[#errors+1] = string.format(
    "%d themes are marked essential = true — expected exactly one built-in default theme",
    essential_theme_found)
end

if #errors > 0 then
  print("cdin-x validation failed:")
  for _, err in ipairs(errors) do print("  - " .. err) end
  os.exit(1)
end

print(string.format("cdin-x structure valid (%d essential extensions, %d essential theme)",
  essential_found, essential_theme_found))
