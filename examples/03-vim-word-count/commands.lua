-- :wordcount, and the counting behind it.
--
-- Registered into X.core.vim.registry rather than written into vim's ex
-- command table, so vim core never has to know the word exists. That is the
-- whole arrangement: a claim made at arm's length, which can be withdrawn.

local core     = require "core"
local registry = require "X.core.vim.registry"

local M = {}

local specs = {}

local function count()
  local dv = core.active_docview()
  if not dv then return nil end

  local doc, words = dv.doc, 0
  for i = 1, #doc.lines do
    for _ in (doc.lines[i] or ""):gmatch("%S+") do words = words + 1 end
  end

  return words, #doc.lines
end

function M.register()
  specs = {
    {
      names = { "wordcount", "wc" },
      help  = "--    :wordcount / :wc  count the words in this buffer",
      run   = function()
        local words, lines = count()
        if not words then
          core.error("No document open")
          return
        end
        core.log("%d words, %d lines", words, lines)
      end,
    },
  }

  for _, spec in ipairs(specs) do registry.register_command(spec) end
end

function M.unregister()
  for _, spec in ipairs(specs) do registry.unregister_command(spec) end
  specs = {}
end

return M
