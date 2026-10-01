-- Window key bindings: Alt+hjkl to move between panes, Ctrl+\ to split,
-- Alt+arrows to resize. Register/unregister are explicit so disabling the
-- plugin gives the strokes back.
local keymap = require "core.input.keymap"

local M = {}

local MAP = {
  -- ── focus (Alt + hjkl, like VEX) ─────────────────────────────────────────
  ["alt+h"] = "window:focus-left",
  ["alt+j"] = "window:focus-down",
  ["alt+k"] = "window:focus-up",
  ["alt+l"] = "window:focus-right",
  ["alt+w"] = "window:focus-next",
  ["alt+p"] = "window:focus-prev-window",

  -- ── split ─────────────────────────────────────────────────────────────────
  ["ctrl+\\"]       = "window:vsplit",
  ["ctrl+shift+\\"] = "window:split",

  -- ── close ─────────────────────────────────────────────────────────────────
  ["alt+c"] = "window:close",
  ["alt+o"] = "window:only",

  -- ── resize (Alt + arrow keys, like VEX) ───────────────────────────────────
  ["alt+right"] = "window:increase-width",
  ["alt+left"]  = "window:decrease-width",
  ["alt+up"]    = "window:increase-height",
  ["alt+down"]  = "window:decrease-height",
  ["alt+="]     = "window:equalize",
}

function M.register()
  keymap.add(MAP)
end

function M.unregister()
  keymap.remove(MAP)
end

return M
