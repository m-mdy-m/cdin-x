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

  -- Runs only when `workspace` is active -- which is to say when its `session`
  -- feature is, since `session` is not a package of its own any more -- and is
  -- undone when either side goes away.
  --
  -- The key is a *package* name, not a feature name. That is what makes the rule
  -- checkable: validate.lua can see that a `with` file reaches into exactly the
  -- package its manifest named, and nowhere else.
  with = {
    workspace = "with/themes.lua",
  },

  entry = "init.lua",
}