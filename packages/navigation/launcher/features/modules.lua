-- Poking at Lua modules: reloading one, and opening the two config files that
-- are loaded as code.
--
-- These three share a shape rather than a subject, and each is small enough that
-- three packages would be three registration cycles for no gain. What they have in
-- common is that each offers a list and acts on the choice.
--
-- No key bindings. These are three deliberate, occasional actions; reaching them
-- through the command palette is the point of having a palette, and binding a
-- chord to each would be a key taken away for no gain.
local core    = require "core"
local common  = require "core.utils.common"
local config  = require "core.config"
local command = require "core.input.command"

local M = {}

-- The same file the runtime loads as a project module on startup. Named here
-- rather than invented, so "open the project module" cannot produce a different
-- file from the one that is actually executed.
local PROJECT_MODULE = ".lite_project.lua"

local MAP = {}

MAP["core:reload-module"] = function()
  core.command_view:enter("Reload Module", function(text, item)
    local name = (item and item.text) or (type(text) == "string" and text or nil)
    if not name or name == "" then return end
    -- Reloading re-runs the module's top-level code, and the runtime already
    -- owns that: core.reload_module drops the name from package.loaded, requires
    -- it again and folds the new table's fields back into the old one, so a table
    -- somebody is holding stays valid. This wraps rather than reimplements it,
    -- because a second copy of the reload is a second thing to keep right.
    --
    -- pcall, not a bare call: a module that fails to require raises, and this is
    -- a user action behind a prompt. The failure belongs in the log next to the
    -- prompt, not as an error thrown out of it.
    local ok, err = pcall(core.reload_module, name)
    if not ok then core.error("Could not reload %q: %s", name, tostring(err)) end
  end, function(text)
    local items = {}
    for name in pairs(package.loaded) do items[#items + 1] = name end
    return common.fuzzy_match(items, text)
  end)
end

MAP["core:open-user-module"] = function()
  core.root_view:open_doc(core.open_doc(config.user_dir .. "/init.lua"))
end

MAP["core:open-project-module"] = function()
  if system.get_file_info(PROJECT_MODULE) then
    core.root_view:open_doc(core.open_doc(PROJECT_MODULE))
  else
    -- Create it: the point of the command is to get to the file, and asking the
    -- user to create one by hand first is a worse answer.
    local doc = core.open_doc()
    core.root_view:open_doc(doc)
    doc:save(PROJECT_MODULE)
  end
end

local NAMES = {
  "core:reload-module",
  "core:open-user-module",
  "core:open-project-module",
}

local enabled = false

function M.enable()
  if enabled then return end
  enabled = true
  command.add(nil, MAP)
end

function M.disable()
  if not enabled then return end
  enabled = false
  command.remove(NAMES)
end

return M