-- lua.lua — single-file language plugin.
-- Manifest fields (name, version, ...) live at the top level of the
-- returned table, same as before; init/unload replace what used to be
-- a separate init.lua, and the syntax.add{} body replaces impl.lua.
return {
  name = "lua",
  version = "0.1.0",
  description = "Lua syntax support",
  author = "cdin Team",
  license = "MIT",
  category = "syntax",
  type = "plugin",
  dependencies = {  },
  min_cdin_version = "0.5.0",
  tags = { "language", "lua" },
  init = function(core, config)
    local syntax = require "core.syntax"

    syntax.add {
      files = "%.lua$",
      headers = "^#!.*[ /]lua",
      comment = "--",
      patterns = {
        { pattern = { '"', '"', '\\' },       type = "string"   },
        { pattern = { "'", "'", '\\' },       type = "string"   },
        { pattern = { "%[%[", "%]%]" },       type = "string"   },
        { pattern = { "%-%-%[%[", "%]%]"},    type = "comment"  },
        { pattern = "%-%-.-\n",               type = "comment"  },
        { pattern = "-?0x%x+",                type = "number"   },
        { pattern = "-?%d+[%d%.eE]*",         type = "number"   },
        { pattern = "-?%.?%d+",               type = "number"   },
        { pattern = "<%a+>",                  type = "keyword2" },
        { pattern = "%.%.%.?",                type = "operator" },
        { pattern = "[<>~=]=",                type = "operator" },
        { pattern = "[%+%-=/%*%^%%#<>]",      type = "operator" },
        { pattern = "[%a_][%w_]*%s*%f[(\"{]", type = "function" },
        { pattern = "[%a_][%w_]*",            type = "symbol"   },
        { pattern = "::[%a_][%w_]*::",        type = "function" },
      },
      symbols = {
        ["if"]       = "keyword",
        ["then"]     = "keyword",
        ["else"]     = "keyword",
        ["elseif"]   = "keyword",
        ["end"]      = "keyword",
        ["do"]       = "keyword",
        ["function"] = "keyword",
        ["repeat"]   = "keyword",
        ["until"]    = "keyword",
        ["while"]    = "keyword",
        ["for"]      = "keyword",
        ["break"]    = "keyword",
        ["return"]   = "keyword",
        ["local"]    = "keyword",
        ["in"]       = "keyword",
        ["not"]      = "keyword",
        ["and"]      = "keyword",
        ["or"]       = "keyword",
        ["goto"]     = "keyword",
        ["self"]     = "keyword2",
        ["true"]     = "literal",
        ["false"]    = "literal",
        ["nil"]      = "literal",
      },
    }
  end,

  unload = function() end,
}
