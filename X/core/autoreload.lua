-- autoreload.lua — single-file core plugin.
-- Manifest fields live at the top level of the returned table, same as
-- before; init/unload replace what used to be a separate init.lua, and
-- the body below (wrapped in do..end so its locals don't leak) replaces
-- what used to be required from impl.lua. The `loaded` guard preserves
-- the original require-once behavior (init.lua used to `require` impl.lua,
-- which Lua's module cache only ever runs once per session).
local loaded = false

return {
  name = "autoreload",
  version = "0.1.0",
  description = "Reload files changed outside CDIN",
  author = "cdin Team",
  license = "MIT",
  category = "core",
  type = "plugin",
  essential = true,
  dependencies = {  },
  min_cdin_version = "0.5.0",
  tags = { "filesystem", "reload" },
  init = function(core, config)
    if loaded then return end
    loaded = true
    do
    local core   = require "core"
    local config = require "core.config"
    local Doc    = require "core.doc"

    local times = setmetatable({}, { __mode = "k" })

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

    core.add_thread(function()
      while true do
        for _, doc in ipairs(core.docs) do
          local info = system.get_file_info(doc.filename or "")
          if info and times[doc] ~= info.modified then
            reload_doc(doc)
          end
          coroutine.yield(0.05)
        end
        coroutine.yield(config.project_scan_rate)
      end
    end)

    table.insert(Doc._after_load, update_time)
    table.insert(Doc._after_save, update_time)
    end
  end,

  unload = function() end,
}
