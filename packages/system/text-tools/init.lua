-- The text-tools package: two conveniences for text that is not English.
--
-- Nothing here that both features need, so nothing here but what keeps the
-- kernel's contract. The features are enabled after this returns and undone
-- before it is called again.
local M = {}

function M.init()
  if M.loaded then return end
  M.loaded = true
end

function M.unload()
  M.loaded = false
end

return M