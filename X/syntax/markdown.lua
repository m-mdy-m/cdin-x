-- markdown.lua — single-file language plugin.
-- Manifest fields (name, version, ...) live at the top level of the
-- returned table, same as before; init/unload replace what used to be
-- a separate init.lua, and the syntax.add{} body replaces impl.lua.
return {
  name = "markdown",
  version = "0.1.0",
  description = "Markdown syntax support",
  author = "cdin Team",
  license = "MIT",
  category = "syntax",
  type = "plugin",
  dependencies = {  },
  min_cdin_version = "0.5.0",
  tags = { "language", "markdown" },
  init = function(core, config)
    local syntax = require "core.syntax"

    syntax.add {
      files = { "%.md$", "%.markdown$" },
      patterns = {
        { pattern = "\\.",                    type = "normal"   },
        { pattern = { "<!%-%-", "%-%->" },    type = "comment"  },
        { pattern = { "```", "```" },         type = "string"   },
        { pattern = { "``", "``", "\\" },     type = "string"   },
        { pattern = { "`", "`", "\\" },       type = "string"   },
        { pattern = { "~~", "~~", "\\" },     type = "keyword2" },
        { pattern = "%-%-%-+",                type = "comment" },
        { pattern = "%*%s+",                  type = "operator" },
        { pattern = { "%*", "[%*\n]", "\\" }, type = "operator" },
        { pattern = { "%_", "[%_\n]", "\\" }, type = "keyword2" },
        { pattern = "#.-\n",                  type = "keyword"  },
        { pattern = "!?%[.-%]%(.-%)",         type = "function" },
        { pattern = "https?://%S+",           type = "function" },
      },
      symbols = { },
    }
  end,

  unload = function() end,
}
