-- Posing over Lua modules: reloading one, and opening the two config files
-- that are loaded as code.
--
-- These three share a shape rather than a subject, and each is small enough
-- that three plugins would be three registration cycles for no gain. What
-- they have in common is that each one offers a list and acts on the choice.
local M = {
  name = "modules",
  version = "0.1.0",
  description = "Reload a loaded module, open the user or project config module",
  author = "cdin Team",
  license = "MIT",
  category = "core",
  type = "plugin",
  essential = false,
  dependencies = {},
  min_cdin_version = "0.5.0",
  tags = { "lua", "config" },
}

M.config = {}

-- No key bindings. These are three deliberate, occasional actions; reaching
-- them through the command palette is the point of having a palette, and
-- binding a chord to each would be a key taken away for no gain.
local NAMES = {
  "core:reload-module",
  "core:open-user-module",
  "core:open-project-module",
}

-- The same file the runtime loads as a project module on startup. Named
-- here rather than invented, so "open the project module" cannot produce a
-- different file from the one that is actually executed.
local PROJECT_MODULE = ".lite_project.lua"

local loaded = false
local help_handle = nil

-- Reloading a module re-runs its top-level code, and the runtime already
-- owns that: core.reload_module drops the name from package.loaded, requires
-- it again and folds the new table's fields back into the old one, so a table
-- somebody is still holding stays valid. This wraps rather than reimplements
-- it, because a second copy of the reload would be a second thing to keep
-- right — and the only thing added here is the reporting.
--
-- pcall, not a bare call: a module that fails to require raises, and this is
-- a user action behind a prompt. The failure belongs in the log next to the
-- prompt, not as an error thrown out of it.
local function reload_module(core, name)
  local ok, err = pcall(core.reload_module, name)
  if not ok then return false, tostring(err) end
  return true
end

local function register()
  local core    = require "core"
  local common  = require "core.utils.common"
  local config  = require "core.config"
  local command = require "core.input.command"

  local map = {}

  map["core:reload-module"] = function()
    core.command_view:enter("Reload Module", function(text, item)
      local name = (item and item.text) or (type(text) == "string" and text or nil)
      if not name or name == "" then return end
      local ok, err = reload_module(core, name)
      if ok then core.log("Reloaded module %q", name) end
    end, function(text)
      local items = {}
      for name in pairs(package.loaded) do items[#items + 1] = name end
      return common.fuzzy_match(items, text)
    end)
  end

  map["core:open-user-module"] = function()
    core.root_view:open_doc(core.open_doc(config.user_dir .. "/init.lua"))
  end

  map["core:open-project-module"] = function()
    if system.get_file_info(PROJECT_MODULE) then
      core.root_view:open_doc(core.open_doc(PROJECT_MODULE))
    else
      -- Create it: the point of the command is to get to the file, and
      -- asking the user to create a file by hand first is a worse answer.
      local doc = core.open_doc()
      core.root_view:open_doc(doc)
      doc:save(PROJECT_MODULE)
    end
  end

  command.add(nil, map)
end

local function unregister()
  require("core.input.command").remove(NAMES)
  if help_handle then
    require("core").unregister_help_shortcuts(help_handle)
    help_handle = nil
  end
end

function M.init(core, config)
  if loaded then return end
  loaded = true
  register()
end

function M.unload()
  if not loaded then return end
  unregister()
  loaded = false
end

return M
