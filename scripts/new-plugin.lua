-- Scaffolds a new package, a new theme, or a new syntax definition.
--
--   lua scripts/new-plugin.lua <name> [category]
--
-- Two shapes, because a theme and a package are genuinely different things and
-- making them look alike is what kept this script wrong:
--
--   a package   packages/<category>/<name>/{package.lua,init.lua,README.md}
--   a theme     packages/system/themes/themes/<name>/theme.lua
--   syntax      X/syntax/<name>.lua
--
-- A package's manifest is its own file. That is the whole reason `package.lua`
-- exists: the catalog reads a name, a version and a dependency list *before* it
-- decides load order, and the only way to do that without executing the package
-- is to not put the manifest in the entry point.
--
-- This used to write `X/<category>/<name>/init.lua` with the manifest inline,
-- and it no longer does. `X/` is still a valid catalog root for a package that
-- has not moved yet, but nothing new goes there — see X/README.md.
--
-- ## Why nothing here goes through string.format
--
-- These templates are full of `%`, because Lua patterns are, and a template full
-- of `%` inside a `string.format` is a countdown. Writing `%.%` where you meant a
-- pattern gives `invalid conversion '%.%' to 'format'`; leaving a `%s` in a
-- comment gives `bad argument #5 to 'format' (no value)`; and both of those
-- happened to this file, which is why it crashed for every category except
-- themes and nobody noticed, because the one category it did work for was not
-- the one the usage text led with.
--
-- So placeholders are `@NAME@` and `@CATEGORY@`, and substitution is a plain
-- `gsub`. A `%` in the body is just a `%`, and there is no arity to get wrong.
--
-- `@NAME@` doubles as the file extension in the syntax template, so
-- `new-plugin.lua zig syntax` writes `%.zig$`. That is only right while the two
-- happen to be the same string, which is why it is one placeholder and not two:
-- a `@EXT@` that nothing substituted is a `files` pattern matching nothing, and
-- a highlighter that claims no file highlights nothing, silently.

local name = arg[1]
local category = arg[2] or "utils"

if not name or not name:match("^[%w._-]+$") then
  print("Usage: lua scripts/new-plugin.lua <name> [category]")
  print("  categories: editing, navigation, system, vcs")
  print("  For a theme: lua scripts/new-plugin.lua <name> themes")
  print("  For a syntax definition: lua scripts/new-plugin.lua <name> syntax")
  os.exit(1)
end

-- `theme` is what people type; a theme is not a package, so it takes a different
-- branch entirely rather than being a category.
local is_theme = category == "themes" or category == "theme"

local base
if is_theme then
  base = "packages/system/themes/themes/" .. name
elseif category == "syntax" then
  base = "X/syntax/" .. name
else
  base = "packages/" .. category .. "/" .. name
end

--- Writes `body` with `@NAME@` replaced by `name`, and `@CATEGORY@` by the
--- category. The two are different values and conflating them is how a manifest
--- ends up claiming `category = "my-plugin"`.
local function fill(body)
  local out = body:gsub("@NAME@", name)
  out = out:gsub("@CATEGORY@", is_theme and "system" or category)
  return out
end

local function mkdir(path)
  local sep = package.config:sub(1, 1)
  if sep == "\\" then
    os.execute('mkdir "' .. path:gsub("/", "\\") .. '" >NUL 2>NUL')
  else
    os.execute('mkdir -p "' .. path:gsub('"', '\\"') .. '"')
  end
end

mkdir(base)

local files = {}

if is_theme then
  -- Copied from packages/system/themes/themes/nord/theme.lua rather than
  -- invented, because the key names are the host's and a wrong one is
  -- invisible: the runtime falls back to the default for a key nobody supplied,
  -- so a misspelled colour key is a theme that quietly looks like another one.
  -- `["function"]` is bracketed because `function` is a reserved word and
  -- `function = "#x"` is not a table constructor.
  files[base .. "/theme.lua"] = fill([[-- @NAME@ theme
--
-- A theme is a table of colours and nothing else. There is no format, no
-- inheritance and no theme engine: the host's theme registry reads the table,
-- resolves any key you did not supply from the default, and hands the result to
-- the style object everything draws with.
--
-- Every colour is a hex string except `search_highlight`, which is an RGBA
-- table because it has to be composited over whatever is behind it.
--
-- A theme ships only when some bundle in bundles/ names it. This file alone
-- does not put it in a build.
return {
  name = "@NAME@",
  background = "#2e3440", background2 = "#272c36", background3 = "#3b4252",
  text = "#eceff4", caret = "#eceff4",
  accent = "#88c0d0",
  dim = "#616e88", divider = "#3b4252", selection = "#3b4252",
  line_number = "#4c566a", line_number2 = "#88c0d0",
  line_highlight = "#333a47", scrollbar = "#272c36", scrollbar2 = "#4c566a",
  search_highlight = { 235, 203, 139, 90 },
  titlebar_text = "#a9b4c7", titlebar_text_focus = "#eceff4",
  titlebar_button_hover = "#434c5e", titlebar_close_hover = "#bf616a",
  vim_pill_fg = "#eceff4", vim_normal_bg = "#434c5e",
  vim_insert_bg = "#2e5f5f", vim_visual_bg = "#5f4c2e",
  vim_replace_bg = "#5f2e2e", vim_command_bg = "#2e5f3a",
  git_modified = "#ebcb8b", git_added = "#a3be8c", git_deleted = "#bf616a",
  git_conflict = "#d08770", git_untracked = "#616e88", git_renamed = "#b48ead",
  syntax = {
    normal = "#eceff4", symbol = "#d8dee9", comment = "#616e88",
    keyword = "#81a1c1", keyword2 = "#5e81ac", number = "#b48ead",
    literal = "#8fbcbb", string = "#a3be8c", operator = "#81a1c1",
    ["function"] = "#88c0d0",
  },
}
]])

elseif category == "syntax" then
  -- The shape is copied from X/syntax/lua.lua, because getting it wrong is
  -- invisible: `core.syntax.add` is called from `init`, so a definition with the
  -- wrong keys registers nothing and highlights nothing, and there is no error.
  --
  -- Every pattern is a **Lua pattern**, not a regular expression. That is why
  -- `%-%-` is a comment and not `--`, and why `%s` is whitespace and not `\s`.
  files[base .. ".lua"] = fill([[-- @NAME@.lua - single-file language definition.
--
-- The manifest fields live at the top level of the returned table, and `init` is
-- what registers the definition. `unload` is empty on purpose: the highlighter
-- has no remove, so there is nothing here that can be undone, and an empty
-- function is a true statement rather than a missing one.
--
-- Every pattern below is a Lua pattern. There is no `\b`; use `%w`, `%d`, `%s`.
-- A `{ "open", "close", "\\" }` pattern is a delimited form, and it is what a
-- string with escapes wants -- a bare `"[^"]*"` stops at the first escaped quote.
return {
  name = "@NAME@",
  version = "0.1.0",
  description = "@NAME@ syntax support",
  author = "cdin Team",
  license = "MIT",
  category = "syntax",
  type = "plugin",
  dependencies = {  },
  min_cdin_version = "0.5.0",
  tags = { "language", "@NAME@" },
  init = function(core, config)
    local syntax = require "core.syntax"

    syntax.add {
      files = "%.@NAME@$",
      headers = "^#!.*[ /]@NAME@",   -- a shebang, for extensionless files
      comment = "#",
      patterns = {
        { pattern = { '"', '"', '\\' },  type = "string"   },
        { pattern = { "'", "'", '\\' },  type = "string"   },
        { pattern = { "@", "@" },        type = "comment"  },  -- your line comment
        { pattern = "#.-\n",            type = "comment"  },
        { pattern = "-?0x%x+",          type = "number"   },
        { pattern = "-?%d+[%d%.eE]*",   type = "number"   },
        { pattern = "[%+%-=/%*%^#<>]",  type = "operator" },
        { pattern = "[%a_][%w_]*",      type = "symbol"   },
      },
      symbols = {
        ["if"]     = "keyword",
        ["else"]   = "keyword",
        ["for"]    = "keyword",
        ["while"]  = "keyword",
        ["return"] = "keyword",
        ["true"]   = "literal",
        ["false"]  = "literal",
        ["nil"]    = "literal",
      },
    }
  end,

  unload = function() end,
}
]], name)

else
  -- Two files, because the two things a package registers are the two things that
  -- have to be undone on unload. A package with only one of them does not need the
  -- split; one with both almost always does.
  files[base .. "/package.lua"] = fill(
[[-- The manifest for the @NAME@ package. Data only: no require, no
-- functions.
--
-- The catalog reads this file to learn the name, the version and the dependency
-- list *before* it decides load order, which is why it is separate from init.lua
-- and why nothing above the table may do anything.
--
-- What a cdin build carries is decided by a bundle in bundles/, never by this
-- file. Nothing here says this one is more important than another.
return {
  name = "@NAME@",
  kind = "plugin",
  version = "0.1.0",
  description = "A CDIN-X package",
  authors = { "cdin Team" },
  license = "MIT",
  tags = {},

  category = "@CATEGORY@",
  min_cdin_version = "0.5.0",

  entry = "init.lua",
}
]])

  files[base .. "/init.lua"] = fill([[-- @NAME@
--
-- init() and unload(), and nothing else. A require at the top of this file would
-- run the whole subtree before the catalog had decided whether to load it at all.
local M = {}

local loaded = false

function M.init(core, config)
  -- The guard is not decoration: this file is dofile'd as the entry point and may
  -- also be require'd by a with entry, and those are two module instances with
  -- two independent guards. Without it both do the work.
  if loaded then return end
  loaded = true
  core.log("@NAME@ loaded")
end

function M.unload()
  if not loaded then return end
  -- Remove whatever init() registered: commands, keymaps, hooks. Removals compare
  -- by identity, so hand back the *same* table you added -- one built fresh at
  -- removal time matches nothing and silently does not undo anything.
  loaded = false
end

return M
]])
end

if is_theme then
  files[base .. "/README.md"] = fill([[# @NAME@

A theme.

## Keys

Every colour the host asks for, and what each one is for:
[docs/building/a-theme.md](../../../docs/building/a-theme.md).

Copy an existing one and change the colours. That is easier than starting from a
list, and it matters that the key names are the host's — a misspelled colour key
is a theme that quietly looks like another one.

## Development

Run `make validate`. A theme ships only if a bundle in `bundles/` names it.
]])
-- A syntax definition is one file beside the others in X/syntax/, and that
-- directory has one README listing all of them. A per-file README would be a
-- second place to forget to update.
elseif category ~= "syntax" then
  files[base .. "/README.md"] = fill([[# @NAME@

A CDIN-X package.

## Usage

Document it here: what it does, and what you press to do it.

## Development

Install it from your own directory with **Install Local** in the manager, then
reload. Run `make validate` before submitting a pull request.
]])
end

--- Whether anything here already exists, so a second run does not truncate it.
--- `new-plugin.lua lua syntax` in this repository would overwrite the real
--- `X/syntax/lua.lua`, and "wb" truncates without asking.
local function existing(paths)
  local hits = {}
  for _, path in ipairs(paths) do
    local f = io.open(path, "rb")
    if f then f:close(); hits[#hits + 1] = path end
  end
  return hits
end

local already = existing((function()
  local out = {}
  for path in pairs(files) do out[#out + 1] = path end
  table.sort(out)
  return out
end)())

if #already > 0 then
  print("Nothing written. These already exist:")
  for _, path in ipairs(already) do print("  " .. path) end
  print("Delete or rename them first, or pick a different name.")
  os.exit(1)
end

for _, path in ipairs((function()
  local out = {}
  for p in pairs(files) do out[#out + 1] = p end
  table.sort(out)
  return out
end)()) do
  local f, err = io.open(path, "wb")
  if not f then
    error(err)
  end
  f:write(files[path])
  f:close()
  print("Created: " .. path)
end

if is_theme then
  print("A theme ships only if a bundle in bundles/ names it. See X/README.md.")
else
  print("Next: make manifest && make validate")
end