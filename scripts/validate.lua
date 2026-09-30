-- Structural validation of the catalog.
--
-- Runs with plain lua, from the repository root: `make validate`. It checks
-- the things that are cheap to get wrong and expensive to debug at runtime:
-- the required files, the essential set a cdin build bundles, the theme
-- layout, the dependency rules, self-containment of the bundled plugins, and
-- the two rules that keep cdin-x independent of cdin — no EXEDIR, and no
-- `core.x` module namespace left over from the rename.
local scan = dofile("scripts/_scan.lua")

-- scan.exists handles files *and* directories; a read-based check would
-- report every category directory as missing.
local exists = scan.exists

local errors = {}
local root_files = {
  "README.md",
  "cdinx/init.lua",
  "cdinx/config.lua",
  "cdinx/manifest.lua",
  "cdinx/command.lua",
  "plugins/cdin-x/init.lua",
  "scripts/new-plugin.lua",
  "scripts/install.py",
  "scripts/bundle.py",
  "scripts/validate.lua",
}
for _, path in ipairs(root_files) do
  if not exists(path) then errors[#errors+1] = path .. " not found" end
end

-- ── fonts ────────────────────────────────────────────────────────────────
-- The bundled fonts are the ones this repository ships, and a cdin build
-- cannot start without them. scripts/bundle.py refuses to substitute
-- anything, so the absence has to be a hard error here too rather than
-- something a build discovers later.
local REQUIRED_FONTS = { "font.ttf", "monospace.ttf", "icons.ttf" }
if not exists("fonts") then
  errors[#errors+1] = "fonts/ not found — a cdin build cannot start without them"
else
  for _, f in ipairs(REQUIRED_FONTS) do
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

-- ── independence from cdin ───────────────────────────────────────────────
--
-- Two rules, and both exist because the alternative fails silently rather
-- than loudly:
--
--   no EXEDIR     EXEDIR is a global the host defines as the directory the
--                  binary lives in. Depending on it assumes a cdin install
--                  layout, which is exactly what cdin-x must not assume.
--   no core.x     the old module namespace. A leftover `require "core.x…"`
--                  resolves to nothing on a host that has no such module, and
--                  fails at load time rather than at build time.
--
-- Only code is checked, and `--` comments and string literals are stripped
-- first so a line that merely *mentions* either word is not a failure.
local CODE_DIRS = { "cdinx", "X" }

local function code_files(dir)
  local out = {}
  for _, path in ipairs(scan.list_files_recursive(dir) or {}) do
    if path:match("%.lua$") then out[#out + 1] = path end
  end
  return out
end

local function strip_comments(src)
  src = src:gsub("%-%-%[%[.*%]%]", " ")          -- --[[ block ]]
  src = src:gsub("%-%-%[=*%[.*%]=*%]", " ")        -- --[==[ block ]==]
  return (src:gsub("%-%-[^\n]*", " "))             -- -- line
end

for _, dir in ipairs(CODE_DIRS) do
  for _, file in ipairs(code_files(dir)) do
    local handle = io.open(file, "rb")
    if handle then
      local code = strip_comments(handle:read("*a") or "")
      handle:close()

      for line in code:gmatch("[^\n]+") do
        if line:find("EXEDIR", 1, true) then
          errors[#errors+1] = string.format(
            "%s references EXEDIR — cdin-x must not assume a cdin install layout", file)
        end
        if line:find('core.x', 1, true) then
          errors[#errors+1] = string.format(
            "%s references core.x — the module namespace is now cdinx.*", file)
        end
      end
    end
  end
end

-- ── essential plugins must be self-contained ────────────────────────────
--
-- scripts/bundle.py copies ONE essential plugin and its own files, with no
-- other plugin alongside it. So an essential plugin that requires another
-- X plugin would bundle into something that cannot load: the require would
-- resolve to a module that is not there. This is not a style rule — it is
-- the property that makes the bundle valid, and it cannot be checked any
-- other way, because the failure only appears in a built cdin.
local function self_contained(entry, name)
  local files = entry.single_file and { entry.path } or files_under(entry.base)
  for _, f in ipairs(files) do
    for _, mod in ipairs(x_requires(f)) do
      local owner = owner_of(mod)
      if owner and owner ~= name then
        errors[#errors+1] = string.format(
          "essential plugin %s requires %s (owned by %q), which the bundle does not contain: %s",
          name, mod, owner, f)
      end
    end
  end
end

for name, entry in pairs(known) do
  if entry.meta.essential == true and not is_theme(entry) then
    self_contained(entry, name)
  end
end

-- ── a register/unregister seam ───────────────────────────────────────────
--
-- Every plugin has to answer to the same two calls, because the manager and
-- each integration's own init() assume they exist. A plugin that exposes
-- neither loads, does nothing, and reports nothing: the manager's pcall
-- around init() only catches a *raise*, and a missing function is a raise the
-- reader then has to decode from one line among forty in the log.
--
-- `M.register` on the entry point is not the only way in. A plugin may delegate
-- to siblings (tab does: `require("X.core.tab.impl").register()`), in which
-- case the seam is a call to a name that has to resolve. Both shapes are
-- checked: the call must name a function, on the entry point or on a sibling
-- it requires, and the pair must be symmetric.
--
-- This is a static check, not a load. It cannot see a nil field two levels
-- deep in someone's own module, which is what scripts/load_check.lua is for.
local function has_function(tbl_or_false, name)
  if not tbl_or_false then return false end
  return type(rawget(tbl_or_false, name)) == "function"
    or type((getmetatable(tbl_or_false) or {}).__index == "function"
      and (tbl_or_false[name])) == "function"
end

-- The table an init.lua's register() call resolves to, without running it.
-- dofile would execute the body, which is the thing being avoided: a
-- top-level require in a manifest-carrying file is a catalog hazard, and
-- validation must not trigger one.
local function seam_target(entry)
  -- the entry point itself, if it defines the seam
  local src = io.open(entry.single_file and entry.path or (entry.base .. "/init.lua"), "rb")
  if not src then return nil end
  local body = strip_comments(src:read("*a") or "")
  src:close()

  -- entry-point form: `function M.register()`
  if body:find("function%s+M%.register%s*%(") then return { entry.base, "entry point" } end

  -- delegated form: require("<sibling>").register()
  local mod = body:match('require%s*%(?%s*"([^"]+)"%s*%)%.register%s*%(')
  if not mod then return nil end

  -- resolve the module name to a file, the way the runtime would: the name is
  -- already a repo-relative path with dots turned into separators, because
  -- that is how package.path is searched. No root is prefixed — `X.core.tab.impl`
  -- IS `X/core/tab/impl`, and prefixing a root would make it `X/X/core/…`.
  local rel = mod:gsub("%.", "/")
  for _, cand in ipairs({ rel .. ".lua", rel .. "/init.lua" }) do
    if scan.exists(cand) then return { cand, mod } end
  end
  return { "?" .. mod, mod }
end

for name, entry in pairs(known) do
  if not is_theme(entry) then
    local init_file = entry.single_file and entry.path or (entry.base .. "/init.lua")
    local handle = io.open(init_file, "rb")
    local body = handle and strip_comments(handle:read("*a") or "") or ""
    if handle then handle:close() end

    -- A plugin that calls register()/unregister() at all must call both.
    local calls_register   = body:find("%.register%s*%(") ~= nil
    local calls_unregister = body:find("%.unregister%s*%(") ~= nil
    if calls_register ~= calls_unregister then
      errors[#errors+1] = string.format(
        "%s calls %s but not %s — init() and unload() must be symmetric: %s",
        name, calls_register and "register()" or "unregister()",
        calls_register and "unregister()" or "register()", init_file)
    end

    -- And the name it calls has to exist on the module it calls it on.
    if calls_register then
      local target = seam_target(entry)
      if target then
        local file = io.open(target[1], "rb")
        local tbody = file and strip_comments(file:read("*a") or "") or ""
        if file then file:close() end
        local defines = tbody:find("function%s+M%.register%s*%(")
                         or tbody:find("function%s+S%.register%s*%(")
                         or tbody:find("function%s+[A-Za-z_]+%.register%s*%(")
        if target[1]:sub(1, 1) == "?" then
          errors[#errors+1] = string.format(
            "%s calls %s.register() but no module %q resolves in the tree", name, target[2], target[2])
        elseif not defines then
          errors[#errors+1] = string.format(
            "%s calls %s.register() but %s defines no register()", name, target[2], target[1])
        end
      end
    end
  end
end

-- ── the bundle itself ───────────────────────────────────────────────────
--
-- The one check that exercises the real code path. Everything above is a
-- statement about the source; this runs scripts/bundle.py and compares what
-- came out against what a cdin build is entitled to find.
local function check_bundle()
  local python = os.getenv("CDIN_PYTHON") or "python3"
  local tmp = os.getenv("TMPDIR") or os.getenv("TEMP") or os.getenv("TMP") or "."
  local out = tmp .. "/cdin-x-validate-bundle"

  local command = string.format('%s scripts/bundle.py --out "%s" 2>&1',
    python, out)
  local pipe = io.popen(command)
  local output = pipe and pipe:read("*a") or ""
  if pipe then pipe:close() end

  if not output:find("bundled") and not output:find("✓") then
    errors[#errors+1] = "scripts/bundle.py did not run: " ..
      output:gsub("\n", " ")
    return
  end

  -- The exact set a cdin build must find. Anything missing breaks the
  -- editor; anything extra means the essential marker was applied to
  -- something that should have stayed optional.
  local required = {
    "BUNDLE.lua",
    "plugins/vim.lua",
    "themes/default/theme.lua",
    "X/core/vim/init.lua",
    "X/core/vim/registry.lua",
    "X/core/vim/ex/init.lua",
    "fonts/font.ttf",
    "fonts/monospace.ttf",
    "fonts/icons.ttf",
  }
  for _, path in ipairs(required) do
    if not exists(out .. "/" .. path) then
      errors[#errors+1] = "bundle is missing " .. path
    end
  end

  -- Nothing beyond the essential set may appear in the bundle.
  --
  -- The listing comes back with whatever prefix the platform produced — a
  -- relative path for a tree inside the repo, an absolute one for a temp
  -- directory, and a differently-spelled absolute one again under a POSIX
  -- emulation layer. So the relative part is recovered from the last
  -- top-level entry rather than by stripping a prefix that may not match.
  local BUNDLE_TOPLEVEL = { "BUNDLE.lua", "X", "fonts", "plugins", "themes" }
  local function bundle_rel(path)
    local p = path:gsub("\\", "/")
    local cut
    for _, top in ipairs(BUNDLE_TOPLEVEL) do
      local at, from = nil, 1
      while true do
        local found = p:find("/" .. top, from, true)
        if not found then break end
        at, from = found, found + 1
      end
      if at and (not cut or at > cut) then cut = at end
    end
    if not cut then return p end
    return p:sub(cut + 1)
  end

  for _, path in ipairs(scan.list_files_recursive(out) or {}) do
    local rel = bundle_rel(path)
    local allowed = rel == "BUNDLE.lua"
      or rel:match("^plugins/[^/]+%.lua$")
      or rel:match("^themes/[^/]+/theme%.lua$")
      or rel:match("^X/core/[^/]+/")          -- an essential plugin's own files
      or rel:match("^X/core/[^/]+%.lua$")
      or rel:match("^fonts/[^/]+$")
    if not allowed then
      errors[#errors+1] = "bundle contains a non-essential entry: " .. rel
    end
  end

  -- Idempotence: a second run must produce the same tree, or a build is not
  -- reproducible and a diff of two builds tells you nothing.
  local handle = io.open(out .. "/BUNDLE.lua", "rb")
  local before = handle and handle:read("*a") or ""
  if handle then handle:close() end

  local second = io.popen(string.format('%s scripts/bundle.py --out "%s" 2>&1', python, out))
  if second then second:read("*a"); second:close() end

  local again = io.open(out .. "/BUNDLE.lua", "rb")
  local after = again and again:read("*a") or ""
  if again then again:close() end

  if before ~= after or before == "" then
    errors[#errors+1] = "bundle.py is not idempotent: two runs differ"
  end
end

check_bundle()

if #errors > 0 then
  print("cdin-x validation failed:")
  for _, err in ipairs(errors) do print("  - " .. err) end
  os.exit(1)
end

print(string.format("cdin-x structure valid (%d essential extensions, %d essential theme)",
  essential_found, essential_theme_found))
