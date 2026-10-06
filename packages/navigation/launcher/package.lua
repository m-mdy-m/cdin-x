-- The manifest for the launcher package. Data only: no require, no functions.
--
-- Three entry points into the editor that share nothing but a shape: each prompts
-- and acts on the choice. They are features because a user who wants the command
-- palette and not the file finder should not pay for the file finder, and
-- because the strokes are the most contested keys in the editor.
return {
  name = "launcher",
  kind = "plugin",
  version = "0.1.0",
  description = "Command palette, file finder, and the Lua module commands",
  authors = { "cdin Team" },
  license = "MIT",
  tags = { "ui", "commands", "files" },

  category = "core",
  min_cdin_version = "0.5.0",

  features = {
    palette = {
      default = true,
      description = "Run any command by name (ctrl+shift+p)",
    },
    finder = {
      default = true,
      description = "Find a file by name, or open a file or folder by path",
    },
    modules = {
      default = true,
      description = "Reload a loaded Lua module, open the user or project config",
    },
  },

  -- Declared here and read from `opts`, not from `config`. This one was
  -- `config.show_keybinds` and a user who set that in their `init.lua` has to move
  -- it: a key the editor never reads, in a package that owns it, is exactly what
  -- declaring an option is for.
  options = {
    show_keybinds = {
      type = "boolean",
      default = true,
      description = "Show the keystroke beside each command in the palette",
    },
  },

  entry = "init.lua",
}