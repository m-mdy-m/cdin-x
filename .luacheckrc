-- luacheck configuration for cdin-x.
--
-- `globals` is empty because nothing in this repository is allowed to create a
-- global. `read_globals` holds what cdin provides and this repository reads.
-- Each name here is a global the host is known to define: the six it sets from C
-- (ARGS, VERSION, PLATFORM, SCALE, EXEFILE, PATHSEP), EXEDIR, and the two host
-- modules it exposes as globals (system, renderer) — both of which cdin-x code
-- already calls. Anything else that shows up as undefined is a bug to fix, not
-- a name to add: `core`, for instance, is a module and has to be required.
std = "lua54"
max_line_length = 100

-- One writable global field, and it is not a global in the sense that matters.
-- The loader hangs its shared state off the `package` table so that reloading
-- cdinx/manager/loader.lua finds what the previous copy left instead of
-- installing a second searcher. It has to be *writable* -- the module creates it
-- on first use -- which is why it is here and not in `read_globals`. No name is
-- created; a field on a table the host already made is.
globals = { "package.cdinx_store" }

read_globals = {
  "ARGS", "VERSION", "PLATFORM", "SCALE", "EXEFILE", "EXEDIR", "PATHSEP",
  "system", "renderer",

  -- `package.loaders` is the Lua 5.1 spelling of `package.searchers`, still read
  -- for a host that is that old. Read-only, so it belongs here rather than in
  -- `globals` above.
  "package.loaders",
}

files["scripts/"] = {
  -- The dev scripts run with plain lua and no editor: they shell out and read
  -- files by path, which is the whole of what they do.
  read_globals = { "io", "os", "arg", "package", "debug" },
}
