local M = {
  name = "unicode_inspect",
  version = "0.2.0",
  description = "Show the codepoints of the selection or the character at the caret",
  author = "cdin Team",
  license = "MIT",
  category = "optional",
  type = "plugin",
  essential = false,
  dependencies = {},
  min_cdin_version = "0.5.0",
  tags = { "unicode", "text", "debug" },
}
M.config = {}

local loaded = false

function M.init()
  if loaded then return end
  loaded = true
  require("X.optional.unicode_inspect.impl").register()
end

function M.unload()
  if not loaded then return end
  require("X.optional.unicode_inspect.impl").unregister()
  loaded = false
end

return M
