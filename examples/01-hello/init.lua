-- hello — the smallest plugin that does something.
--
-- Two files, because the two things a plugin registers are the two things
-- that have to be undone on unload. A plugin with only one of them doesn't
-- need the split; one with both almost always does.
--
-- The manifest is the table this file returns, and nothing above `init()` is
-- required — the catalog reads this file with dofile() to learn the name and
-- dependencies, and a top-level require would run the whole subtree just to
-- look the plugin up.
local M = {
  name        = "hello",
  version     = "0.1.0",
  description = "Says hello, to show the shape of a plugin",
  author      = "you",
  license     = "MIT",
  category    = "optional",
  type        = "plugin",
  essential   = false,
}

local loaded = false

function M.init(core, config)
  -- The guard is not optional. A plugin dofile'd by the catalog and then
  -- require'd by an integration is two module instances with two
  -- independent guards, and without this both of them do the work.
  if loaded then return end
  loaded = true

  require("hello.commands").register()
  require("hello.keymap").register()

  M.help = core.register_help_shortcuts {
    { key = "ctrl+alt+h", desc = "Say hello" },
  }
end

function M.unload()
  if not loaded then return end

  -- Everything init() registered, undone. A key left behind fights the next
  -- plugin to bind it; a command left behind keeps firing after the plugin
  -- that owned it is gone.
  require("hello.keymap").unregister()
  require("hello.commands").unregister()

  if M.help then
    require("core").unregister_help_shortcuts(M.help)
    M.help = nil
  end

  loaded = false
end

return M
