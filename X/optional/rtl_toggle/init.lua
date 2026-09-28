-- Optional: toggle right-to-left text direction and Arabic shaping.
--
-- The manifest is inline (there is no manifest.lua), and impl.lua is
-- required inside init() so the extension catalog can dofile() this file
-- to read the manifest without registering anything.
local M = {
  name = "rtl_toggle",
  version = "0.2.0",
  description = "Toggle RTL text direction and Arabic shaping",
  author = "cdin Team",
  license = "MIT",
  category = "optional",
  type = "plugin",
  essential = false,
  dependencies = {},
  min_cdin_version = "0.5.0",
  tags = { "rtl", "text", "i18n" },
}
M.config = {}

local loaded = false

function M.init()
  if loaded then return end
  loaded = true
  require("X.optional.rtl_toggle.impl").register()
end

function M.unload()
  if not loaded then return end
  require("X.optional.rtl_toggle.impl").unregister()
  loaded = false
end

return M
