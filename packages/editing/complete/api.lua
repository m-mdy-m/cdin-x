-- Autocomplete: a suggestion popup fed by *providers*.
--
-- This module is the plugin's public surface and the seam other plugins
-- extend. A provider supplies items, optionally narrowed to files matching
-- a pattern; the popup fuzzy-matches them against what has been typed and
-- shows the result. Nothing here knows where the items came from.
--
--   api.lua     this file — the provider registry
--   source.lua  the built-in provider: symbols from all open documents
--   suggest.lua matching, dedup and the current suggestion list
--   popup.lua   geometry and drawing of the suggestion box
--   commands.lua accept / previous / next / cancel
--   keymap.lua  Tab, Up, Down, Escape
--
-- The manifest is inline (there is no manifest.lua) and the siblings are
-- required inside init(), so the extension catalog can dofile() this file
-- to read the manifest without patching RootView for a plugin that may
-- never be loaded.
local core   = require "core"
local config = require "core.config"

local M = {}

if config.autocomplete_max_suggestions == nil then
  config.autocomplete_max_suggestions = 6
end

-- ── provider registry ────────────────────────────────────────────────────
-- name -> { files = <pattern>, items = { { text, info }, ... } }
--
-- `files` is matched against the active document's filename (see
-- core.utils.common.match_pattern); a provider with no pattern applies
-- everywhere. Replacing a provider of the same name is how a provider
-- refreshes its contents, which is what the built-in one does on every
-- rescan.
local providers = {}

-- Every item carries this so common.fuzzy_match, which scores
-- tostring(item), sees the text rather than the table's address. Exported
-- because suggest.lua folds a run of equal items into one merged entry and
-- the merged entry has to be the same shape as the ones it replaces — a
-- second metatable here would be a second thing to keep in step.
M.ITEM_MT = { __tostring = function(t) return t.text end }
local mt = M.ITEM_MT

-- spec = {
--   name  = "open-docs",
--   files = "%.lua$",            -- optional; defaults to everything
--   items = { foo = "info", ... } -- a set keyed by text, or a list of
--                                 -- { text = ..., info = ... } tables
-- }
function M.set(spec)
  assert(type(spec) == "string" or spec.name, "autocomplete provider needs a name")
  local name = type(spec) == "string" and spec or spec.name
  local raw  = type(spec) == "string" and {} or (spec.items or {})

  local items = {}
  if #raw > 0 then
    -- already a list of items
    for _, item in ipairs(raw) do
      items[#items + 1] = setmetatable({ text = item.text, info = item.info }, mt)
    end
  else
    -- a set keyed by text, as the symbol scanner produces
    for text, info in pairs(raw) do
      items[#items + 1] = setmetatable({
        text = text,
        info = type(info) == "string" and info or nil,
      }, mt)
    end
  end

  providers[name] = { files = (type(spec) == "table" and spec.files) or ".*", items = items }
end

-- Kept under its old name: the built-in provider and any third-party
-- provider written against the original API call autocomplete.add().
M.add = M.set

function M.remove(name)
  providers[name] = nil
end

function M.clear()
  providers = {}
end

function M.provider_names()
  local out = {}
  for name in pairs(providers) do out[#out + 1] = name end
  table.sort(out)
  return out
end

-- ── state shared with the rest of the plugin ─────────────────────────────
-- The partial word being completed, the filtered suggestions, and which one
-- is selected. suggest.lua owns the logic; popup.lua and commands.lua read
-- these.
M.partial   = ""
M.suggestions = {}
M.suggestions_idx = 1
M.last_line, M.last_col = nil, nil

function M.reset()
  M.suggestions_idx = 1
  M.suggestions = {}
end

-- ── load point ───────────────────────────────────────────────────────────
local loaded = false
local restore = nil

function M.register()
  if loaded then return end
  loaded = true

  local suggest  = require "complete.suggest"
  local popup    = require "complete.popup"
  local source   = require "complete.source"
  local RootView = require "core.rootview"
  local DocView  = require "core.views.docview"

  suggest.refresh_providers(providers)

  local function active_view()
    if getmetatable(core.active_view) == DocView then
      return core.active_view
    end
  end

  source.start(M.set)

  -- The popup is drawn by deferring from RootView.draw, and updated from
  -- the text-input and update hooks. Core has no event system, so the three
  -- methods are wrapped and the originals restored on unload.
  local original = {
    on_text_input = RootView.on_text_input,
    update        = RootView.update,
    draw         = RootView.draw,
  }

  RootView.on_text_input = function(...)
    original.on_text_input(...)
    local av = active_view()
    if not av then return end
    M.partial = suggest.partial_symbol(av.doc)
    if #M.partial >= 3 then
      suggest.update(av.doc, M.partial, providers)
      M.last_line, M.last_col = av.doc:get_selection()
    else
      M.reset()
    end
    -- keep the box on screen when it would otherwise run off the bottom
    local _, y, _, h = popup.rect(av)
    local limit = av.position.y + av.size.y
    if y + h > limit then
      av.scroll.to.y = av.scroll.y + y + h - limit
    end
  end

  RootView.update = function(...)
    original.update(...)
    local av = active_view()
    if av then
      local line, col = av.doc:get_selection()
      if line ~= M.last_line or col ~= M.last_col then M.reset() end
    end
  end

  RootView.draw = function(...)
    original.draw(...)
    local av = active_view()
    if av then
      core.root_view:defer_draw(function() popup.draw(av) end)
    end
  end

  restore = function()
    RootView.on_text_input = original.on_text_input
    RootView.update        = original.update
    RootView.draw          = original.draw
    restore = nil
  end

  require("complete.commands").register()
  require("complete.keymap").register()
end

function M.unregister()
  if not loaded then return end
  require("complete.keymap").unregister()
  require("complete.commands").unregister()
  if restore then restore() end
  loaded = false
end

-- Exposed for the plugin's own init.lua to publish on core, mirroring how
-- search and menu are reached.
M.core = core
M.config = config

return M
