-- The manifest for the text-tools package. Data only: no require, no functions.
--
-- Two small conveniences for working with text that is not English: one changes
-- how text is laid out, the other tells you what the bytes are. They share a
-- package and nothing else, so each is a feature and either can be off alone.
return {
  name = "text-tools",
  kind = "plugin",
  version = "0.2.0",
  description = "Right-to-left layout and Arabic shaping, and a codepoint inspector",
  authors = { "cdin Team" },
  license = "MIT",
  tags = { "rtl", "i18n", "unicode" },

  category = "core",
  min_cdin_version = "0.5.0",

  features = {
    rtl = {
      default = true,
      description = "Toggle text direction and Arabic shaping (ctrl+alt+r, ctrl+alt+s)",
    },
    unicode = {
      default = true,
      description = "Show the codepoints of the selection or of the character at the caret",
    },
  },

  entry = "init.lua",
}