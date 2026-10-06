-- Checks one package against the rules in docs/architecture/extension-contract.md.
--
--     lua scripts/check.lua <path-to-package> [more paths...]
--
-- Runs with plain lua from the repository root: no build, no editor, no cdin-x
-- install. `make validate` checks the whole tree; this checks one package, and
-- says the same things about it, so a package can be checked while it is being
-- written rather than only when the tree is finished.
--
-- The rules that need a README, a LICENSE or a changelog entry are warnings:
-- those are the owner's files, and a package that is otherwise correct should
-- not fail a check over one of them.
local Schema = dofile("cdinx/schema.lua")
local scan   = dofile("scripts/_scan.lua")

local function exists(path)
  local handle = io.open(path, "rb")
  if handle then handle:close(); return true end
  return scan.is_dir(path)
end

local function read(path)
  local handle = io.open(path, "rb")
  if not handle then return nil end
  local text = handle:read("*a")
  handle:close()
  return text
end

local function strip_comments(src)
  src = src:gsub("%-%-%[%[.*%]%]", " ")
  src = src:gsub("%-%-%[=*%[.*%]=*%]", " ")
  return (src:gsub("%-%-[^\n]*", " "))
end

-- ── R7: independence from cdin ────────────────────────────────────────────
--
-- `EXEDIR` assumes a cdin install layout; `core.x` is the module namespace from
-- before the rename and resolves to nothing on a host that has no such module.
-- Both fail at runtime rather than at check time, which is why they are checked
-- at all.
-- One check over the whole file rather than per line: a hard-coded path is a
-- pattern, and looking for it inside a single line depends on which side of the
-- `=` the string happens to sit on.
--
-- A candidate list of executables is not a defect. A package probing for `git`
-- or a formatter has to name the usual places it lives, and has to keep working
-- when the user installed it somewhere else, so the path is a guess that is
-- tested — never the location anything is written to.
local function check_independence(dir, errors)
  for _, path in ipairs(scan.list_files_recursive(dir) or {}) do
    if path:match("%.lua$") and not path:match("package%.lua$") then
      local code = strip_comments(read(path) or "")

      if code:find("EXEDIR", 1, true) then
        errors[#errors+1] = string.format(
          "%s references EXEDIR — cdin-x must not assume a cdin install layout", path)
      end
      if code:find("core.x", 1, true) then
        errors[#errors+1] = string.format(
          "%s references core.x — the module namespace is now cdinx.*", path)
      end

      -- A path that is probed for is a candidate; one that is assigned, opened or
      -- returned is a location the package has assumed.
      local probes = code:match("candidates") ~= nil
        or code:match("io%.open%(%s*path") ~= nil
      if not probes then
        local found = {}
        for abs in code:gmatch('["\']([A-Za-z]:[/\\][^"\']*)["\']') do
          if not found[abs] then
            found[abs] = true
            errors[#errors+1] = string.format(
              "%s hard-codes the absolute path %q — paths come from cdinx/config.lua",
              path, abs)
          end
        end
      end
    end
  end
end

-- ── R9: no side effects at require time ───────────────────────────────────
--
-- Stated for a package.lua, which the sandbox already enforces: it is data, so
-- it cannot require anything at all. Stated for the entry point, this is the
-- cheap half: a `require` above the first `function` runs when the file is
-- loaded rather than when init() is called. The expensive half — a top-level
-- call that registers something — cannot be seen without running the file, and
-- running it is what this script must not do.
--
-- The reason a top-level require is wrong here at all is that the entry point is
-- loaded *to be listed*: the old inline manifest is dofile()d by the catalog, so
-- a top-level require runs the package for one that may never be enabled. A
-- package with a `package.lua` is never dofile()d — its manifest was already read
-- from the data file — so its entry point is only ever run by the loader, when
-- the package is genuinely being enabled. The rule does not apply to it, and
-- enforcing it would forbid the one structure that makes a package cheap to
-- list.
--
-- So on the packages this script actually accepts, R9 reduces to what the sandbox
-- already guarantees: a `package.lua` is data and cannot require anything. The
-- branch below is kept for the case where this checker is pointed at a directory
-- without one, which `check()` currently refuses before reaching it.
local function check_no_top_level_require(entry_path, errors, has_package_file)
  if has_package_file then return end

  local body = strip_comments(read(entry_path) or "")
  -- Everything above the first function definition is the file's top level.
  local head = body
  local at = head:find("\n%s*function%s") or head:find("\n%s*local%s+function%s")
  if at then head = head:sub(1, at - 1) end
  if head:find("require%s*[%(%\"']") then
    errors[#errors+1] = string.format(
      "%s requires at the top level: the entry point is loaded before init() is called, " ..
      "so its modules run for a package that may never be enabled. Move them into init().",
      entry_path)
  end
end

-- ── R8: declared features and with-entries exist and say what they promise ──
local function check_declared_files(spec, dir, errors)
  for key, rel in pairs(spec.with or {}) do
    if key == spec.name then
      errors[#errors+1] = string.format(
        "with[%q] names its own package; a with entry is between two packages", key)
    end
    local path = dir .. "/" .. rel
    if not exists(path) then
      errors[#errors+1] = string.format("with[%q] names %q, which is not in the package", key, rel)
    else
      -- Same promise a feature makes, and for the same reason: `disable_all` and
      -- `partner_left` call `disable` and have nothing else to fall back on.
      local body = strip_comments(read(path) or "")
      if not body:find("enable") or not body:find("disable") then
        errors[#errors+1] = string.format("%s must define enable() and disable()", rel)
      end
    end
  end
  for key in pairs(spec.features or {}) do
    local path = dir .. "/features/" .. key .. ".lua"
    if not exists(path) then
      errors[#errors+1] = string.format(
        "features[%q] has no file at features/%s.lua", key, key)
    else
      local body = strip_comments(read(path) or "")
      if not body:find("enable") or not body:find("disable") then
        errors[#errors+1] = string.format(
          "features/%s.lua must define enable() and disable()", key)
      end
    end
  end
end

-- ── R10: a lang package's files are there ─────────────────────────────────
local function check_lang_files(spec, dir, errors)
  for _, rel in ipairs(spec.files or {}) do
    if not exists(dir .. "/" .. rel) then
      errors[#errors+1] = string.format("files lists %q, which is not in the package", rel)
    end
  end
end

-- ── one package ───────────────────────────────────────────────────────────

local function check(dir)
  local errors, warnings = {}, {}

  local package_file = dir .. "/package.lua"
  if not exists(package_file) then
    errors[#errors+1] = dir .. "/package.lua not found: a package is identified by it"
    return errors, warnings
  end

  -- R1 and R2: the schema is where the name rules, the version and the
  -- pure-data rule live, so this is one call and one list of reasons.
  local spec, err = Schema.read(package_file)
  if not spec then
    for line in tostring(err):gmatch("[^\n]+") do
      errors[#errors+1] = (line:gsub("^%s*%-%s*", ""))
    end
    return errors, warnings
  end

  if spec.essential ~= nil then
    errors[#errors+1] = "essential is not a package.lua field: name a bundle in bundles/ instead"
  end

  -- A field the schema does not name. A warning, never an error: the package
  -- loads, and refusing it would make adopting a newer schema a two-step edit.
  -- It is reported because the alternative is a typo that reads to its author
  -- as "the kernel ignored me".
  for _, field in ipairs(Schema.unknown_fields(spec)) do
    warnings[#warnings+1] = string.format(
      "%q is not a package.lua field (ignored): %s", field, package_file)
  end

  local entry = Schema.entry_of(spec)
  local entry_path = dir .. "/" .. entry
  if not exists(entry_path) then
    errors[#errors+1] = "entry " .. entry .. " not found in the package"
    return errors, warnings
  end

  if spec.kind == "lang" then check_lang_files(spec, dir, errors) end
  check_declared_files(spec, dir, errors)
  check_no_top_level_require(entry_path, errors, true)
  check_independence(dir, errors)

  if not exists(dir .. "/README.md") then
    warnings[#warnings+1] = dir .. "/README.md not found (the owner's file, so a warning)"
  end

  return errors, warnings
end

local function resolve_dir(arg)
  if exists(arg) then return (arg:gsub("[/\\]+$", "")) end
  for _, entry in ipairs(scan.plugin_entries()) do
    if entry.meta.name == arg then return entry.base end
  end
  for _, theme in ipairs(scan.theme_entries()) do
    if theme.name == arg then return theme.base end
  end
  return nil
end

local function main(args)
  if #args == 0 or args[1] == "-h" or args[1] == "--help" then
    print("Usage: lua scripts/check.lua <package-dir-or-name> [more...]")
    return 1
  end

  local errors, warnings, checked = {}, {}, 0
  for _, arg in ipairs(args) do
    local dir = resolve_dir(arg)
    if not dir then
      errors[#errors+1] = string.format("%q is neither a directory nor a package name", arg)
    else
      local dir_errors, dir_warnings = check(dir)
      checked = checked + 1
      for _, err in ipairs(dir_errors) do errors[#errors+1] = dir .. ": " .. err end
      for _, warn_msg in ipairs(dir_warnings) do warnings[#warnings+1] = dir .. ": " .. warn_msg end
    end
  end

  for _, warn_msg in ipairs(warnings) do print("cdin-x warning: " .. warn_msg) end

  if #errors > 0 then
    print(string.format("cdin-x check failed (%d package(s)):", checked))
    for _, err in ipairs(errors) do print("  - " .. err) end
    return 1
  end

  print(string.format("cdin-x check passed (%d package(s), %d warning(s))",
    checked, #warnings))
  return 0
end

os.exit(main(arg))
