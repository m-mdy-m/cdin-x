-- The manifest for the update package. Data only: no require, no
-- functions.
return {
  name = "update",
  kind = "plugin",
  version = "0.2.0",
  description = "Check CDIN releases and offer updates",
  authors = { "cdin Team" },
  license = "MIT",
  tags = { "update", "releases" },

  category = "core",
  min_cdin_version = "0.5.0",

  entry = "init.lua",
}