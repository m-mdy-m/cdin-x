local core    = require "core"
local command = require "core.input.command"
local keymap  = require "core.input.keymap"

local M = {}

local function utf8_len_from(b)
  if b >= 0xF0 then return 4 elseif b >= 0xE0 then return 3 elseif b >= 0xC0 then return 2 end
  return 1
end

local function inspect()
  local dv = core.active_docview()
  if not dv then core.error("No active doc"); return end
  local doc = dv.doc

  local text
  if doc:has_selection() then
    local l1, c1, l2, c2 = doc:get_selection(true)
    text = doc:get_text(l1, c1, l2, c2)
  else
    local line, col = doc:get_selection()
    local ltext = doc.lines[line] or ""
    text = ltext:sub(col, col + utf8_len_from(ltext:byte(col) or 0) - 1)
  end

  if text == nil or text == "" then core.log("Empty"); return end

  local ok, u = pcall(require, "core.text.utf8")
  if not ok or not u then
    core.log("bytes: %d", #text)
    return
  end

  local parts = {}
  local pos, n = 1, #text
  while pos <= n and #parts < 32 do
    local cp, nxt = u.decode(text, pos)
    parts[#parts + 1] = string.format("U+%04X", cp)
    pos = nxt
  end
  core.log("%s  (%d chars)", table.concat(parts, " "), u.len(text))
end

local MAP = { ["unicode:inspect"] = inspect }
local NAMES = { "unicode:inspect" }

local KEYS = { ["ctrl+alt+u"] = "unicode:inspect" }

function M.register()
  command.add("core.views.docview", MAP, true)
  keymap.add(KEYS, true)
end

function M.unregister()
  keymap.remove(KEYS)
  command.remove(NAMES)
end

return M
