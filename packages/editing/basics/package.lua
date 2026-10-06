-- The manifest for the basics package. Data only: no require, no functions.
--
-- Two small conveniences that have nothing in common with each other and always
-- travel together, split into features so a user who wants neither pays for
-- neither.
return {
  name = "basics",
  kind = "plugin",
  version = "0.1.0",
  description = "Reload files changed outside the editor and trim trailing whitespace on save",
  authors = { "cdin Team" },
  license = "MIT",
  tags = { "filesystem", "formatting" },

  category = "core",
  min_cdin_version = "0.5.0",

  features = {
    autoreload = {
      default = true,
      description = "Reload a document when the file changes underneath it",
    },
    trimwhitespace = {
      default = true,
      description = "Trim trailing whitespace before every save",
    },
  },

  entry = "init.lua",
}