-- Cache of which files are read-only.
--
-- Was a bare local inside treeview_impl.lua, which meant the command
-- registrations could not be moved into their own module without also
-- dragging the whole view along. Kept separate so both the badge renderer
-- and commands.lua can reach the same table.
--
-- Entries are dropped whenever the tree is rebuilt, because a file can be
-- made writable while cdin is running.
local M = {}

M.store = {}

function M.flush()
  M.store = {}
end

return M
