-- vim-word-count — the same idea as 02-word-count, reached from vim mode.
--
-- This is an *integration*, and the difference is not cosmetic. Vim core must
-- not know that word counting exists, or removing the plugin that does the
-- counting would leave a :wordcount that quietly does nothing. So instead of
-- patching vim, this claims two of the seams vim offers and nothing else.
--
-- It is self-contained on purpose. It could `require "word-count"` and reuse
-- that count, but then it would be a second thing to uninstall together, and
-- an integration that drags in a capability it doesn't need is how a catalog
-- stops being predictable. Nineteen lines of counting is cheaper than that
-- coupling.

local M = {
  name         = "vim-word-count",
  version      = "0.1.0",
  description  = "Adds :wordcount and gc to vim mode",
  author       = "you",
  license      = "MIT",
  category     = "integration",
  type         = "plugin",
  dependencies = { "vim" },
}

local loaded = false

function M.init(core, config)
  if loaded then return end
  loaded = true

  require("vim-word-count.commands").register()
  require("vim-word-count.keymap").register()
end

function M.unload()
  if not loaded then return end

  -- keymap first, then commands: the reverse of init(). Not because the
  -- order matters to the registry, which does not care, but because it makes
  -- the two lines below read in the same direction as the two above.
  require("vim-word-count.keymap").unregister()
  require("vim-word-count.commands").unregister()

  loaded = false
end

return M
