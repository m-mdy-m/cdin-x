-- The manifest for the themes package. Data only: no require, no functions.
--
-- `kind` is "plugin", not "theme": this package is not one theme, it is a
-- directory of them plus the thing that switches between them. A `theme` package
-- is a single `<name>/theme.lua` and its own name starts with `theme-`; this one
-- is a container, and pretending otherwise would make the schema demand a prefix
-- that says nothing true.
return {
  name = "themes",
  kind = "plugin",
  version = "0.2.0",
  description = "The bundled themes, and a switcher for them",
  authors = { "cdin Team" },
  license = "MIT",
  tags = { "theme", "ui" },

  category = "core",
  min_cdin_version = "0.5.0",

  features = {
    switcher = {
      default = true,
      description = "Change theme from a searchable list (ctrl+alt+t)",
    },
  },

  -- Runs only when `session` is active too, and is undone when either side goes
  -- away. Phase 5 teaches the kernel what a `with` entry is; until then this is
  -- declared and validated but not run.
  with = {
    session = "with/themes.lua",
  },

  entry = "init.lua",
}