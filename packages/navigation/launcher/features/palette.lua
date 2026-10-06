-- The command palette: every command, by name, fuzzy-matched.
--
-- A user-facing workflow, not a mechanism. The runtime keeps what it is built on
-- — the command registry, `command.get_all_valid()`, `core.command_view` — and
-- this file is the part that asks the user which command they meant.
--
-- `show_keybinds` is this package's own option, declared in package.lua, so it is
-- read from `opts` and not from the editor's `config`. It used to be
-- `config.show_keybinds`, and a user who set that in their `init.lua` needs to
-- move it to `packages.lua` — a config key the editor never reads, in a package
-- that owns it, is the whole point of declaring it here.
local core    = require "core"
local common  = require "core.utils.common"
local command = require "core.input.command"
local keymap  = require "core.input.keymap"

local M = {}

-- Hoisted: removal compares by identity, and a table built fresh at removal time
-- matches nothing and the command survives the feature being switched off.
local MAP = {}
local KEYS = { ["ctrl+shift+p"] = "core:find-command" }
local NAMES = { "core:find-command" }

local opts = { show_keybinds = true }
local help_handle = nil
local enabled = false

function M.palette()
  -- Read the registry on every open, not once at load: a command registered or
  -- unloaded by something else while the palette was closed has to be there when
  -- it is next used.
  local commands = command.get_all_valid()

  core.command_view:enter("Do Command", function(_, item)
    if not item then return end
    command.perform(item.command)
  end, function(text)
    local res = common.fuzzy_match(commands, text)
    for i, name in ipairs(res) do
      res[i] = {
        text = command.prettify_name(name),
        -- Shown on the right of each row, next to the command name.
        info = opts.show_keybinds and keymap.get_binding(name) or nil,
        command = name,
      }
    end
    return res
  end)
end

--- `opts` is the package's merged options, handed over by the kernel: declared
--- defaults with the user's overrides on top. A feature that has none ignores it.
--- @param given table|nil
function M.enable(given)
  if enabled then return end
  enabled = true

  if given then opts = given end
  MAP["core:find-command"] = M.palette
  command.add(nil, MAP)
  keymap.add(KEYS)

  -- The empty view's quick reference, so the keystroke is discoverable without
  -- it being hardcoded into the runtime's help.
  help_handle = core.register_help_shortcuts({
    { key = "ctrl+shift+p", desc = "Command palette", section = true },
  })
end

function M.disable()
  if not enabled then return end
  enabled = false

  keymap.remove(KEYS)
  command.remove(NAMES)
  if help_handle then
    core.unregister_help_shortcuts(help_handle)
    help_handle = nil
  end
end

return M