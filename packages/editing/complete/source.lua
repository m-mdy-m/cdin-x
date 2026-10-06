-- The built-in autocomplete provider: symbols taken from every open
-- document.
--
-- This is what makes completion useful with no configuration — type three
-- characters of a name you have seen anywhere in the project and it is
-- offered. It is a provider like any other, registered through
-- autocomplete.add(), so a language-specific provider can sit alongside
-- it rather than replacing it.
--
-- Scanning happens on a coroutine so a large project never blocks a
-- frame, and each document's symbol set is cached against its change id so
-- an unchanged document is not re-scanned on every pass.
local core = require "core"
local api  = require "complete.api"

local M = {}

M.PROVIDER_NAME = "open-docs"

local function scan(doc, pattern)
  local symbols = {}
  local i = 1
  while i < #doc.lines do
    for sym in doc.lines[i]:gmatch(pattern) do
      symbols[sym] = true
    end
    i = i + 1
    -- yield periodically so a long document cannot stall the frame loop
    if i % 100 == 0 then coroutine.yield() end
  end
  return symbols
end

-- Start the background scanner. `publish` is the plugin's provider setter,
-- injected rather than required so this module stays independent of how the
-- registry is exposed.
function M.start(publish)
  local pattern = require("core.config").symbol_pattern

  core.add_thread(function()
    -- weak keys: a closed document drops out of the cache on its own
    local cache = setmetatable({}, { __mode = "k" })

    local function cached(doc)
      local entry = cache[doc]
      if entry and entry.last_change_id == doc:get_change_id() then
        return entry.symbols
      end
      local symbols = scan(doc, pattern)
      cache[doc] = { last_change_id = doc:get_change_id(), symbols = symbols }
      return symbols
    end

    while true do
      local symbols = {}
      for _, doc in ipairs(core.docs) do
        for sym in pairs(cached(doc)) do symbols[sym] = true end
        coroutine.yield()
      end

      publish { name = M.PROVIDER_NAME, items = symbols }

      -- Idle until some document actually changes.
      repeat
        coroutine.yield(1)
        local stale = false
        for _, doc in ipairs(core.docs) do
          if not cache[doc] or cache[doc].last_change_id ~= doc:get_change_id() then
            stale = true
            break
          end
        end
      until stale
    end
  end)
end

function M.stop()
  api.remove(M.PROVIDER_NAME)
end

return M
