-- The launcher package: three ways into the editor that prompt and act.
--
-- Nothing here that all three features need, so nothing here but the contract
-- the kernel relies on: `init` and `unload` tolerate being called twice and being
-- called in the wrong order, and the features are enabled after this returns and
-- undone before it is called again.
--
-- The package's options are not read here. The kernel merges them and hands them
-- to each feature's `enable`, so there is one place that knows what an option
-- means and it is not the one that has to know which features use it.
local M = {}

function M.init()
  if M.loaded then return end
  M.loaded = true
end

function M.unload()
  M.loaded = false
end

return M