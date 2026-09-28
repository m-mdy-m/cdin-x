local core = require "core"
local project = require "core.project"
local M = {}

function M.selected_items(view)
  local out = {}
  for _, item in pairs(view.selected or {}) do out[#out + 1] = item end
  if #out == 0 and view.hovered_item then out[1] = view.hovered_item end
  return out
end

function M.context_dir(view)
  local item = M.selected_items(view)[1]
  if not item then return "." end
  if item.type == "dir" then return item.filename end
  return item.filename:match("^(.*)[\\/][^\\/]+$") or "."
end

function M.refresh(view, cache, readonly_cache, providers)
  cache.flush()
  for path in pairs(readonly_cache) do readonly_cache[path] = nil end
  view._last_project_files = nil
  core.redraw = true
  project.request_rescan(core)
  if providers then providers() end
end

function M.request_project_rescan()
  project.request_rescan(core)
end

return M
