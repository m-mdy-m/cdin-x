-- The manifest for the complete package. Data only: no require, no
-- functions.
return {
  name = "complete",
  kind = "plugin",
  version = "0.2.0",
  description = "Symbol-based completion popup for open documents, extensible with providers",
  authors = { "cdin Team" },
  license = "MIT",
  tags = { "completion", "symbols" },

  category = "core",
  min_cdin_version = "0.5.0",

  entry = "init.lua",
}