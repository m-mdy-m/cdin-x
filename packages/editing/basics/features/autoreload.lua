-- Reload a document when the file changes underneath it.
--
-- A thread and two document hooks, all three of which have to come back off.
-- The thread is the awkward one: it is an infinite loop, so it is stopped by
-- being told to stop rather than by being cancelled -- `core.add_thread` has no
-- cancel. It also takes the weak owner the style guide asks for, so that if the
-- last reference to this module goes away the thread goes with it instead of
-- outliving the editor.
local core   = require "core"
local Doc    = require "core.doc"
local config = require "core.config"

local M = {}

-- Last-modified time per document, keyed by the document and weak so a closed
-- document is not kept alive by this table.
local times = setmetatable({}, { __mode = "k" })

-- False once `disable` has run. The thread checks it on every pass and returns.
local running = false

local function update_time(doc)
  if not doc.filename then return end
  local info = system.get_file_info(doc.filename)
  if info then times[doc] = info.modified end
end

local function reload_doc(doc)
  local fp = io.open(doc.filename, "r")
  if not fp then return end
  local text = fp:read("*a")
  fp:close()

  local sel = { doc:get_selection() }
  doc:remove(1, 1, math.huge, math.huge)
  doc:insert(1, 1, text:gsub("\r", ""):gsub("\n$", ""))
  doc:set_selection(table.unpack(sel))

  update_time(doc)
  doc:clean()
  core.log_quiet("Auto-reloaded doc \"%s\"", doc.filename)
end

--- Removes a function from one of the document hook lists, and says whether it
--- was there. The lists are plain arrays the host appends to, so undoing a
--- registration means finding the entry rather than replacing the list: the host
--- and every other package hold the same table.
local function remove_hook(list, fn)
  for i = #list, 1, -1 do
    if list[i] == fn then
      table.remove(list, i)
      return true
    end
  end
  return false
end

function M.enable()
  if running then return end
  running = true

  core.add_thread(function()
    while running do
      for _, doc in ipairs(core.docs) do
        local info = system.get_file_info(doc.filename or "")
        if info and times[doc] ~= info.modified then
          reload_doc(doc)
        end
        coroutine.yield(0.05)
      end
      coroutine.yield(config.project_scan_rate)
    end
  end, M)

  table.insert(Doc._after_load, update_time)
  table.insert(Doc._after_save, update_time)
end

function M.disable()
  if not running then return end
  running = false

  remove_hook(Doc._after_load, update_time)
  remove_hook(Doc._after_save, update_time)
end

return M