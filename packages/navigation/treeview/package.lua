-- The manifest for the treeview package. Data only: no require, no functions.
return {
  name = "treeview",
  kind = "plugin",
  version = "0.2.0",
  description = "File tree sidebar with navigation and filesystem actions",
  authors = { "cdin Team" },
  license = "MIT",
  tags = { "navigation", "filesystem", "sidebar" },

  category = "core",
  min_cdin_version = "0.5.0",

  entry = "init.lua",
}