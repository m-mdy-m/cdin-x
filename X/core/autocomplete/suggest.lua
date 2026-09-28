-- Turning a set of providers into the list of suggestions to show.
--
-- Split out of the old single-file implementation so the matching rules
-- live apart from the popup that draws the result and the provider that
-- produces the items.
local common = require "core.utils.common"
local config = require "core.config"
local api    = require "X.core.autocomplete.api"

local M = {}

-- The word being completed: from the start of the word up to the caret.
function M.partial_symbol(doc)
  local translate = require "core.doc.translate"
  local line2, col2 = doc:get_selection()
  local line1, col1 = doc:position_offset(line2, col2, translate.start_of_word)
  return doc:get_text(line1, col1, line2, col2)
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
  for i = 1, config.autocomplete_max_suggestions do
    suggestions[i] = items[j]
    -- items is sorted, so equal texts are adjacent: fold them into one
    -- entry rather than showing the same word several times.
    while items[j] and suggestions[i] and items[i].text == items[j].text do
      suggestions[i].info = suggestions[i].info or items[j].info
      j = j + 1
    end
  end

  api.suggestions = suggestions
  api.suggestions_idx = 1
end

return M
