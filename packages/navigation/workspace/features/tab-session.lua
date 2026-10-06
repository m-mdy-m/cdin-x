-- Include the open tabs in the saved session, and restore them next run.
--
-- This was a separate integration package because it needs two capabilities --
-- tabs, and the session's quit hook -- and neither should know about the other.
-- Inside one package it is a feature, and the ordering the integration used to
-- have to declare is the ordering the features are enabled in: `session` before
-- `tab-session`, because `tab-session` subscribes to session.on_quit().
--
-- `session.lua` is required inside `enable` and held, for the same reason as the
-- other three features.
local session = nil

local M = {}

local enabled = false

function M.enable()
  if enabled then return end
  enabled = true
  session = require "workspace.tab-session.session"
  session.register()
end

function M.disable()
  if not enabled then return end
  enabled = false
  if session then
    session.unregister()
    session = nil
  end
end

return M