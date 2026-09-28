-- Public window manager facade. Context, focus, mutation and teardown
-- operations are split across sibling modules.
local Ops      = require "X.core.window.manager.ops"
local Focus    = require "X.core.window.manager.focus"
local Teardown = require "X.core.window.manager.teardown"
local Context  = require "X.core.window.manager.context"

local M = {}
for k, v in pairs(Ops) do M[k] = v end
for k, v in pairs(Focus) do M[k] = v end
for k, v in pairs(Teardown) do M[k] = v end
M.context = Context
return M
