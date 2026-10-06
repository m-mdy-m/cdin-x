-- The basics package: two conveniences, switched independently.
--
-- There is nothing here that both features need, so there is nothing here but
-- what keeps the kernel's contract: `init` and `unload` tolerate being called
-- twice and being called in the wrong order, and the features are enabled after
-- this returns and undone before it is called again.
local M = {}

function M.init()
  if M.loaded then return end
  M.loaded = true
end

function M.unload()
  M.loaded = false
end

return M