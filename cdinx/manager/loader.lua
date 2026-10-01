-- Makes `require "X.…"` work for extensions installed into the user's store.
--
-- Every extension's own code names its modules by their place in the
-- repository: treeview does `require "X.core.treeview.treeview_impl"`,
-- vim-git does `require "X.integration.vim.vim-git.commands"`. In a build
-- those resolve, because the bundle carries <data>/X/core/treeview/…. But the
-- manager stores an installed extension WITHOUT the X/ prefix:
--
--   <extension_dir>/core/treeview/init.lua
--
-- and nothing told Lua that `X.core.treeview.*` lives there. So the manager
-- could download, place and `dofile` an extension's init.lua, and the first
-- `require` inside init() failed with "module 'X.core.treeview.treeview_impl'
-- not found" -- for every installed extension that has more than one file.
--
-- This is a package searcher, not a package.path entry, because the mapping
-- is not a path template: "X." has to be dropped and the rest turned into
-- directories. It sits AFTER the standard Lua-file searcher, so whatever the
-- build bundles still wins and the store only fills in what is not bundled.
local Loader = {}

-- One state table shared across reloads of this module, so a reload (or two
-- copies of cdin-x) never stacks a second searcher.
local state = rawget(package, "cdinx_store")
if not state then
  state = { dir = nil, fn = nil }
  package.cdinx_store = state
end

local function searcher(name)
  local rest = name:match("^X%.(.+)$")
  if not rest then return nil end

  local dir = state.dir
  if not dir or dir == "" then return nil end

  local rel = (rest:gsub("%.", "/"))
  local notes = {}
  for _, suffix in ipairs({ ".lua", "/init.lua" }) do
    local path = dir .. "/" .. rel .. suffix
    local fp = io.open(path, "rb")
    if fp then
      fp:close()
      local chunk, err = loadfile(path)
      if not chunk then
        error(string.format("error loading module '%s' from file '%s':\n\t%s",
          name, path, tostring(err)), 0)
      end
      return chunk, path
    end
    notes[#notes + 1] = "\n\tno file '" .. path .. "' (cdin-x extension store)"
  end
  return table.concat(notes)
end

-- Points the searcher at `dir` (the extension store) and makes sure it is
-- registered exactly once. Safe to call as often as you like.
function Loader.ensure(dir)
  state.dir = dir
  local list = package.searchers or package.loaders
  if not list then return false end

  for _, fn in ipairs(list) do
    if fn == state.fn then return true end
  end

  state.fn = searcher
  -- After preload (1) and the Lua-file searcher (2): bundled modules win.
  table.insert(list, math.min(3, #list + 1), searcher)
  return true
end

Loader.searcher = searcher
return Loader
