-- What a search matches, and nothing else.
--
-- Pure on purpose: no core, no Manager, no renderer. A filter that reaches
-- into the catalog is a filter nobody can test, and this is the part that
-- decides what the user sees when they type.
local Search = {}

function Search.normalize(query)
  return (query or ""):lower()
end

function Search.fuzzy(haystack, needle)
  if needle == "" then return 0 end

  local score, run, first = 0, 0, nil
  local at = 1
  for i = 1, #needle do
    local c = needle:sub(i, i)
    local found = haystack:find(c, at, true)
    if not found then return nil end
    if i == 1 then first = found end
    if found == at then
      run = run + 1
      score = score + 10 + run * 5
    else
      run = 0
      -- Gaps cost, and a big gap costs more than a small one.
      score = score - math.min(20, (found - at) * 2)
    end
    at = found + 1
  end

  return score - (first or 1) - math.floor(#haystack / 8)
end

-- One entry, one query. `entry` is { name, description, category }.
--
-- Substring over the name, the description and the category first: that is
-- what "find me the one about trees" means, and it is exact. Fuzzy second,
-- so "tv" still finds "treeview". Never the other way round - a fuzzy match
-- that quietly returns things the user did not ask for is worse than a miss.
function Search.matches(entry, query)
  query = Search.normalize(query)
  if query == "" then return true end

  local name = (entry.name or ""):lower()
  local description = (entry.description or ""):lower()
  local category = (entry.category or ""):lower()

  if name:find(query, 1, true) then return true end
  if description:find(query, 1, true) then return true end
  if category:find(query, 1, true) then return true end

  return Search.fuzzy(name, query) ~= nil
end

-- The same decision, with a score, for sorting: exact name prefix first,
-- then substring, then fuzzy. Returns nil when there is no match at all.
function Search.score(entry, query)
  query = Search.normalize(query)
  if query == "" then return 0 end

  local name = (entry.name or ""):lower()
  if name:sub(1, #query) == query then return 10000 - #name end
  if name:find(query, 1, true) then return 5000 - #name end
  if (entry.description or ""):lower():find(query, 1, true) then return 2000 end
  if (entry.category or ""):lower():find(query, 1, true) then return 1000 end

  local fuzzy = Search.fuzzy(name, query)
  if fuzzy then return fuzzy end
  return nil
end

return Search
