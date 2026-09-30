-- word-count — reads the active document and draws a status pill.
--
-- The first example registered a command and stopped. This one does the two
-- things almost every real plugin ends up doing: reaching into the document,
-- and putting something on screen.
--
-- Both go through the host rather than around it. The document comes from
-- core.active_docview(), and the status bar has a registry
-- (core.register_status_pill) precisely so that a plugin never has to draw
-- anything itself.

local M = {
  name        = "word-count",
  version     = "0.1.0",
  description = "Counts the words in the active document and shows it in the status bar",
  author      = "you",
  license     = "MIT",
  category    = "optional",
  type        = "plugin",
  essential   = false,
}

-- Counts runs of non-space characters. Deliberately crude: it is here to
-- show the plumbing, and a real word counter has to deal with unicode word
-- boundaries, which is a much larger conversation.
local function count_words(text)
  local n = 0
  for _ in text:gmatch("%S+") do n = n + 1 end
  return n
end

-- Walks the document. Returns nil when there isn't one, so a caller can tell
-- "no document" from "a document with no words in it".
local function measure()
  local dv = require("core").active_docview()
  if not dv then return nil end

  local doc          = dv.doc
  local words, chars = 0, 0

  for i = 1, #doc.lines do
    local line = doc.lines[i] or ""
    words = words + count_words(line)
    chars = chars + #line
  end

  return words, #doc.lines, chars
end

-- Cached, because the status bar asks for a pill on every draw and a large
-- file makes that a real cost.
--
-- doc.undo_stack.idx is the cheapest "did anything change" signal the host
-- offers today. It is an implementation detail rather than a promise, so this
-- comment is the honest description: a plugin that cares should ask the
-- extension contract for a real change counter instead of depending on this
-- one quietly.
local cache = { doc = nil, idx = nil, words = nil, lines = nil, chars = nil }

function M.stats()
  local dv = require("core").active_docview()
  if not dv then
    cache.doc, cache.idx = nil, nil
    return nil
  end

  local doc = dv.doc
  local idx = doc.undo_stack and doc.undo_stack.idx

  if cache.doc ~= doc or cache.idx ~= idx then
    cache.doc, cache.idx = doc, idx
    cache.words, cache.lines, cache.chars = measure()
  end

  return cache.words, cache.lines, cache.chars
end

function M.characters()
  local _, _, chars = M.stats()
  return chars or 0
end

local loaded = false

function M.init(core, config)
  if loaded then return end
  loaded = true

  -- A provider, not a value. Returning nil draws nothing, which is how a
  -- plugin stays out of the way when it has nothing to say — the pill
  -- disappears rather than sitting there showing a zero.
  core.register_status_pill("word-count", function()
    local words, lines = M.stats()
    if not words then return nil end
    return ("%d words  %d lines"):format(words, lines),
           "vim_normal_bg", "vim_pill_fg"
  end)

  require("word-count.commands").register()

  M.help = core.register_help_shortcuts {
    { key = "ctrl+alt+w", desc = "Count words in the current document" },
  }
end

function M.unload()
  if not loaded then return end

  require("word-count.commands").unregister()

  local core = require "core"
  core.unregister_help_shortcuts(M.help)
  M.help = nil

  -- The pill registry is keyed, so removing the key is the whole of it.
  -- Left behind, it would keep calling M.stats() on a plugin that is no
  -- longer loaded — a small leak that never announces itself.
  if core._status_pills then core._status_pills["word-count"] = nil end

  cache.doc, cache.idx = nil, nil
  loaded = false
end

return M
