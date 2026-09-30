-- The command palette: every command, by name, fuzzy-matched.
--
-- This is a user-facing workflow, not a mechanism, so it is an optional
-- plugin. The runtime keeps the mechanism it is built on — the command
-- registry, command.get_all_valid(), and core.command_view — and this file
-- is the part that asks the user which one they meant.
--
-- The manifest is inline and nothing is required at the top of the file, so
-- the catalog can dofile() this to read the manifest without opening the
-- command view as a side effect.
local M = {
  name = "palette",
  version = "0.1.0",
  description = "Command palette: run any command by name",
  author = "cdin Team",
  license = "MIT",
  category = "core",
  type = "plugin",
  essential = false,
  dependencies = {},
  min_cdin_version = "0.5.0",
  tags = { "ui", "commands" },
}

M.config = {
  -- Shown on the right of each row, next to the command name.
  show_keybinds = true,
}

local KEYS = {
  ["ctrl+shift+p"] = "core:find-command",
}

local NAMES = { "core:find-command" }

local loaded = false
local help_handle = nil

local function register()
  local core    = require "core"
  local common  = require "core.utils.common"
  local command = require "core.input.command"
  local keymap  = require "core.input.keymap"

  local function palette()
    -- Read the registry on every open, not once at load: a command
    -- registered or unloaded by something else while the palette was closed
    -- has to be there when it is next used.
    local commands = command.get_all_valid()

    core.command_view:enter("Do Command", function(_, item)
      if not item then return end
      command.perform(item.command)
    end, function(text)
      local res = common.fuzzy_match(commands, text)
      for i, name in ipairs(res) do
        res[i] = {
          text = command.prettify_name(name),
          info = M.config.show_keybinds and keymap.get_binding(name) or nil,
          command = name,
        }
      end
      return res
    end)
  end

  command.add(nil, { ["core:find-command"] = palette })
  keymap.add(KEYS)

  -- The empty view's quick reference, so the keystroke is discoverable
  -- without it being hardcoded into the runtime's help.
  help_handle = core.register_help_shortcuts({
    { key = "ctrl+shift+p", desc = "Command palette", section = true },
  })
end

local function unregister()
  require("core.input.keymap").remove(KEYS)
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
