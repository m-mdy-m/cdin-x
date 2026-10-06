local core = require "core"
local Cache = require "treeview.cache"
local M = {}

function M.get_cached(view, item)
  local rev = core.project_files_revision or 0
  if rev ~= view._last_revision then
    Cache.invalidate_skips()
    view._last_revision = rev
  end
  return Cache.get(item)
end

function M.each_item(view)
  return coroutine.wrap(function()
    local ox, oy = view:get_content_offset()
    local y = oy + require("core.style").padding.y
    local w = view.size.x
    local h = view:get_item_height()
    local i = 1

    while i <= #core.project_files do
      local item = core.project_files[i]
      local cached = M.get_cached(view, item)
      coroutine.yield(cached, ox, y, w, h)
      y = y + h
      i = i + 1

      if not cached.expanded then
        if cached.skip then
          i = cached.skip
        else
          local depth = cached.depth
          while i <= #core.project_files do
            local separators = 0
            for _ in core.project_files[i].filename:gmatch("[\\/]") do separators = separators + 1 end
            if separators <= depth then break end
            i = i + 1
          end
          cached.skip = i
        end
      end
    end
  end)
end

function M.is_file_readonly(cache, abs_path)
  if not abs_path or abs_path == "" then return false end
  local cached = cache[abs_path]
  if cached ~= nil then return cached end
  local fp = io.open(abs_path, "r+b")
  if fp then
    fp:close()
    cache[abs_path] = false
  else
    cache[abs_path] = true
  end
  return cache[abs_path]
end

function M.truncate_name(font, name, max_w)
  local ellipsis = "…"
  if font:get_width(name) <= max_w then return name end
  local stem, ext = name:match("^(.+)(%.[^%.]+)$")
  if not stem then stem, ext = name, "" end
  local suffix = ellipsis .. ext
  local avail_w = max_w - font:get_width(suffix)
  if avail_w <= 0 then return suffix end
  local trimmed = stem
  while #trimmed > 1 and font:get_width(trimmed) > avail_w do trimmed = trimmed:sub(1, -2) end
  return trimmed .. suffix
end

return M
