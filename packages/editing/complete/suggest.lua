-- Turning a set of providers into the list of suggestions to show.
--
-- Split out of the old single-file implementation so the matching rules
-- live apart from the popup that draws the result and the provider that
-- produces the items.
local common = require "core.utils.common"
local config = require "core.config"
local api    = require "complete.api"

local M = {}
local mt = api.ITEM_MT

-- The word being completed: from the start of the word up to the caret.
function M.partial_symbol(doc)
  local translate = require "core.doc.translate"
  local line2, col2 = doc:get_selection()
  local line1, col1 = doc:position_offset(line2, col2, translate.start_of_word)
  return doc:get_text(line1, col1, line2, col2)
end

-- Recompute the suggestion list from the current provider set, for the word
-- already being completed.
--
-- This is what register() calls after the providers exist but before any
-- keystroke has arrived, so the box has something to show the moment the
-- plugin is live rather than only after the first character. It is the same
-- code path as update(), with the arguments it would have been given, rather
-- than a second implementation of "what should the list be".
--
-- There is deliberately no document here: the caller is at load time, with no
-- active view, so the filename used for the provider pattern match is empty
-- and only providers with a pattern that accepts "" contribute. That is the
-- correct answer for a load-time refresh — the real, filename-narrowed list is
-- produced by update() the moment there is a document to narrow against.
function M.refresh_providers(providers)
  M.update(nil, api.partial or "", providers)
end

-- Collect every item from every provider whose file pattern matches, then
-- fuzzy-match against `partial` and keep the top N, collapsing duplicates
-- and merging their info strings.
function M.update(doc, partial, providers)
  local filename = doc and doc.filename or ""

  local items = {}
  for _, provider in pairs(providers) do
    if common.match_pattern(filename, provider.files) then
      for _, item in pairs(provider.items) do
        items[#items + 1] = item
      end
    end
  end

  items = common.fuzzy_match(items, partial)

  local suggestions = {}
  local j = 1
  -- `j` is the cursor into the matched items and advances on its own: the
  -- inner loop collapses a run of equal texts onto one output entry, so the
  -- two counters have to move independently. A plain `for i = 1, N` filled
  -- the same slot N times instead, and the box never grew past a single row.
  while #suggestions < config.autocomplete_max_suggestions and items[j] do
    local entry = items[j]
    local merged = { text = entry.text, info = entry.info }
    j = j + 1
    -- items is sorted, so equal texts are adjacent: fold them into one entry
    -- rather than showing the same word several times, keeping the first
    -- info string seen for it.
    while items[j] and items[j].text == merged.text do
      merged.info = merged.info or items[j].info
      j = j + 1
    end
    setmetatable(merged, mt)
    suggestions[#suggestions + 1] = merged
  end

  api.suggestions = suggestions
  api.suggestions_idx = 1
end

return M
