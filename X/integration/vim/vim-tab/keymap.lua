-- Normal-mode key bindings for vim-tab: gt and gT, with an optional count
-- in front (3gt goes to the third tab).
--
-- These go into registry.register_gmap, so vim mode only knows that
-- "g" + <key> is a two-key sequence it should resolve; it never learns
-- that "t" means "switch tab". :tabnext and friends are in commands.lua.
local registry = require "X.core.vim.registry"

local M = {}

local GMAP = {
  gt = function(count)
    local tabs = require "X.core.tab.manager"
    if count then tabs.go_to(count) else tabs.next() end
  end,
  gT = function()
    require("X.core.tab.manager").prev()
  end,
}

function M.register()
  registry.register_gmap(GMAP)
end

function M.unregister()
  registry.unregister_gmap(GMAP)
end

return M
