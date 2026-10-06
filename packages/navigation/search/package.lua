-- The manifest for the search package. Data only: no require, no functions.
return {
  name = "search",
  kind = "plugin",
  version = "0.2.0",
  description = "Document search/replace and project-wide search",
  authors = { "cdin Team" },
  license = "MIT",
  tags = { "search", "find", "replace", "project" },

  category = "core",
  min_cdin_version = "0.5.0",

  entry = "init.lua",
}