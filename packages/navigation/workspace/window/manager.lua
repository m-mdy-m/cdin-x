-- Public window manager facade. Context, focus, mutation and teardown
-- operations are split across sibling modules.
local Ops      = require "workspace.window.manager.ops"
local Focus    = require "workspace.window.manager.focus"
local Teardown = require "workspace.window.manager.teardown"
local Context  = require "workspace.window.manager.context"

local M = {}
for k, v in pairs(Ops) do M[k] = v end
for k, v in pairs(Focus) do M[k] = v end
for k, v in pairs(Teardown) do M[k] = v end
M.context = Context
return M
