-- Drawing the suggestion box: where it goes and what it looks like.
--
-- Split out of the old single-file implementation so the geometry and the
-- painting live apart from the matching that decides what is in the box.
local common = require "core.utils.common"
local style  = require "core.style"
local api    = require "complete.api"

local M = {}

-- x, y, width, height of the box, positioned just under the caret and
-- offset back by the width of the partial word. Zero-sized when there is
-- nothing to show, which is also what the scroll correction checks for.
function M.rect(view)
  local suggestions = api.suggestions
  if #suggestions == 0 then
    return 0, 0, 0, 0
  end

  local line, col = view.doc:get_selection()
  local x, y = view:get_line_screen_position(line)
  x = x + view:get_col_x_offset(line, col - #api.partial)
  y = y + view:get_line_height() + style.padding.y

  local font = view:get_font()
  local th   = font:get_height()

  local max_width = 0
  for _, s in ipairs(suggestions) do
    local w = font:get_width(s.text)
    if s.info then
      w = w + style.font:get_width(s.info) + style.padding.x
    end
    max_width = math.max(max_width, w)
  end

  return
    x - style.padding.x,
    y - style.padding.y,
    max_width + style.padding.x * 2,
    #suggestions * (th + style.padding.y) + style.padding.y
end

function M.draw(view)
  local suggestions = api.suggestions

  local rx, ry, rw, rh = M.rect(view)
  renderer.draw_rect(rx, ry, rw, rh, style.background3)

  local font = view:get_font()
  local lh   = font:get_height() + style.padding.y
  local y    = ry + style.padding.y / 2

  for i, s in ipairs(suggestions) do
    local selected = (i == api.suggestions_idx)
    common.draw_text(font, selected and style.accent or style.text,
                     s.text, "left", rx + style.padding.x, y, rw, lh)
    if s.info then
      -- the info column is dimmed until the entry it describes is selected
      common.draw_text(style.font, selected and style.text or style.dim,
                       s.info, "right", rx, y, rw - style.padding.x, lh)
    end
    y = y + lh
  end
end

return M
