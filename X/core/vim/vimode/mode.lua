-- Vim's per-view mode (normal / insert / visual) and its status label.
local core = require "core"

local M = {
  NORMAL = "normal",
  INSERT = "insert",
  VISUAL = "visual",
}

function M.get(view)
  return view.vim_mode or M.NORMAL
end

function M.set(view, mode)
  view.vim_mode = mode
  core.redraw = true
end

-- "[NORMAL]" / "[INSERT]" / "[VISUAL]", or nil when vim mode is off or no
-- document is active.
function M.label(view)
  local mode = M.get(view)
  if     mode == M.INSERT then return "[INSERT]"
  elseif mode == M.VISUAL then return "[VISUAL]"
  else                         return "[NORMAL]"
  end
end

return M
