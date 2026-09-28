-- Vim's own motion keys, and the cdin command each one runs.
local M = {}

M.KEYS = {
  h = { "doc:move-to-previous-char",       "doc:select-to-previous-char"       },
  l = { "doc:move-to-next-char",           "doc:select-to-next-char"           },
  j = { "doc:move-to-next-line",           "doc:select-to-next-line"           },
  k = { "doc:move-to-previous-line",       "doc:select-to-previous-line"       },
  w = { "doc:move-to-next-word-end",       "doc:select-to-next-word-end"       },
  b = { "doc:move-to-previous-word-start", "doc:select-to-previous-word-start" },
  e = { "doc:move-to-next-word-end",       "doc:select-to-next-word-end"       },
}

function M.command_for(key, visual)
  local pair = M.KEYS[key]
  if not pair then return nil end
  return visual and pair[2] or pair[1]
end

return M
