-- Vim's contributions to the status bar and to the home screen.
local core   = require "core"
local config = require "core.config"
local style  = require "core.style"
local mode   = require "X.core.vim.vimode.mode"

local M = {}

local PILL = {
  normal = { bg = "vim_normal_bg",  label = "NORMAL" },
  insert = { bg = "vim_insert_bg",  label = "INSERT" },
  visual = { bg = "vim_visual_bg",  label = "VISUAL" },
}

if style.set_fallback then
  style.set_fallback("vim_pill_fg",     "#eeeeff")
  style.set_fallback("vim_normal_bg",   "#30303a")
  style.set_fallback("vim_insert_bg",   "#12345a")
  style.set_fallback("vim_visual_bg",   "#4a3300")
end

function M.register()
  if core.register_status_pill then
    core.register_status_pill("vim_mode", function()
      if not config.vim_mode_enabled then return nil end
      local view = core.active_docview()
      if not view then return nil end
      local label = mode.label(view)
      local info  = PILL[label:match("%[(.+)%]"):lower()] or PILL.normal
      return info.label, info.bg, "vim_pill_fg"
    end)
  end

  if core.register_help_shortcuts then
    core.register_help_shortcuts({
      { key = "i / Esc", desc = "Insert / Normal mode" },
      { key = ":q / :wq", desc = "Quit / Save & Quit" },
    })
  end
end

function M.unregister() end

return M
