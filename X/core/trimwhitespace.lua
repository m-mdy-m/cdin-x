-- trimwhitespace.lua — single-file core plugin.
-- Manifest fields live at the top level of the returned table, same as
-- before; init/unload replace what used to be a separate init.lua, and
-- the body below (wrapped in do..end so its locals don't leak) replaces
-- what used to be required from impl.lua. The `loaded` guard preserves
-- the original require-once behavior (init.lua used to `require` impl.lua,
-- which Lua's module cache only ever runs once per session).
local loaded = false

return {
  name = "trimwhitespace",
  version = "0.1.0",
  description = "Trim trailing whitespace on save",
  author = "cdin Team",
  license = "MIT",
  category = "core",
  type = "plugin",
  essential = true,
  dependencies = {  },
  min_cdin_version = "0.5.0",
  tags = { "formatting" },
  init = function(core, config)
    if loaded then return end
    loaded = true
    do
    local core    = require "core"
    local command = require "core.input.command"
    local Doc     = require "core.doc"

    local function trim_trailing_whitespace(doc)
      local cline, ccol = doc:get_selection()
      for i = 1, #doc.lines do
        local old_text = doc:get_text(i, 1, i, math.huge)
        local new_text = old_text:gsub("%s*$", "")

        if cline == i and ccol > #new_text then
          new_text = old_text:sub(1, ccol - 1)
        end

        if old_text ~= new_text then
          doc:insert(i, 1, new_text)
          doc:remove(i, #new_text + 1, i, math.huge)
        end
      end
    end

    command.add("core.views.docview", {
      ["trim-whitespace:trim-trailing-whitespace"] = function()
        trim_trailing_whitespace(core.active_view.doc)
      end,
    })

    -- Register _before_save hook instead of monkey-patching Doc.save
    table.insert(Doc._before_save, trim_trailing_whitespace)
    end
  end,

  unload = function() end,
}
