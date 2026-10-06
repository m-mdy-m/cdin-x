-- The manifest for the menu package. Data only: no require, no functions.
return {
  name = "menu",
  kind = "plugin",
  version = "0.2.0",
  description = "Generic searchable menu that features extend with their own sections",
  authors = { "cdin Team" },
  license = "MIT",
  tags = { "ui", "menu" },

  category = "core",
  min_cdin_version = "0.5.0",

  entry = "init.lua",
}