-- core.lua — single-file core plugin.
-- The essential CDIN-X integration marker; it cannot be removed.
-- Kept separate from the runtime's own core/ (one level up, outside X/)
-- — this is just the catalog entry that marks "the built-in bundle" as
-- present and installed, matching the old core/core/ plugin folder.
return {
  name = "core",
  version = "0.1.0",
  description = "CDIN built-in core extensions",
  author = "cdin Team",
  license = "MIT",
  category = "core",
  type = "plugin",
  essential = true,
  dependencies = {},
  min_cdin_version = "0.5.0",
  tags = { "essential", "system", "core" },

  config = {},

  init = function(core, config)
    core.log("CDIN core extension bundle active")
  end,

  unload = function() end,
}
