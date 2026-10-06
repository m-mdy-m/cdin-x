-- Restore open files, project and theme when the editor starts.
--
-- `api` is required inside `enable`, and held, for the same reason as the tab
-- feature: it is module-level state, and a second require would give back a
-- fresh table that knows nothing about what it registered.
--
-- Every key this feature writes is a *host* config key -- session_restore,
-- session_restore_dir, session_restore_theme, session_max_recent,
-- session_save_on_quit -- because the host reads them when it starts and when it
-- quits. They are not package options and are not namespaced: a value the editor
-- never reads is a value that looks set and does nothing.
local api = nil

local M = {}

local enabled = false

function M.enable()
  if enabled then return end
  enabled = true
  api = require "workspace.session.api"
  api.register()
end

function M.disable()
  if not enabled then return end
  enabled = false
  if api then
    api.unregister()
    api = nil
  end
end

return M