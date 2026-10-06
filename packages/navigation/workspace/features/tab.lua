-- Tab management: new, close, reorder, and go to a tab by number.
--
-- `impl` is required inside `enable`, not at the top of this file: a feature is
-- only loaded when it is switched on, so a top-level require would build the tab
-- machinery for a user who closed tabs.
local impl = nil

local M = {}

local enabled = false

function M.enable()
  if enabled then return end
  enabled = true
  -- Held so `disable` reaches the same table: impl keeps module-level state, and
  -- requiring it again would hand back a fresh one that knows nothing about what
  -- it registered.
  impl = require "workspace.tab.impl"
  impl.register()
end

function M.disable()
  if not enabled then return end
  enabled = false
  if impl then
    impl.unregister()
    impl = nil
  end
end

return M