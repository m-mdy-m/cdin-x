-- CDIN-X Plugin Manager panel.
local core    = require "core"
local config  = require "core.config"
local Manager = require "cdinx.manager"
local PanelView   = require "cdinx.panel.view"
local PanelCmds   = require "cdinx.panel.commands"
local PanelKeymap = require "cdinx.panel.keymap"

local M = {}

config.pluginmanager_size = config.pluginmanager_size or 460 * SCALE
config.pluginmanager_min  = config.pluginmanager_min  or 300 * SCALE

-- ── the catalog, in the shape rows.lua wants ─────────────────────────────

local function catalog_notice()
  local roots = Manager.roots()
  local state = Manager.catalog_state()

  if state == "fetching" then
    return "Downloading the extension list..."
  end
  if state == "failed" then
    return "Extension list download failed (see log, ctrl+shift+l).  ctrl+r retries."
  end
  if not roots.registry then
    return "No extension list yet.  Press ctrl+r to download it."
  end
  return nil
end

local function collect()
  local entries = {}
  Manager.scan()

  for name, plugin in pairs(Manager.list()) do
    local status = Manager.get_status(name)
    local locked  = Manager.is_locked(name)

    local group = "available"
    if locked then
      group, status = "editor", "editor"
    elseif status == "installed" or status == "disabled" then
      group = "installed"
    end

    entries[#entries + 1] = {
      name        = name,
      category    = plugin.category,
      version     = plugin.version,
      description = plugin.description,
      source      = plugin._source,
      status      = status,
      locked      = locked,
      group       = group,
    }
  end

  return entries
end

-- ── the instance ─────────────────────────────────────────────────────────

M.view = PanelView(function()
  return collect(), catalog_notice()
end)
M.view.target_width = config.pluginmanager_size

local node = core.root_view:get_active_node()
node:split("right", M.view, true)

PanelCmds.bind(M.view)

M.commands = PanelCmds
M.keymap   = PanelKeymap

function M.register()
  PanelCmds.register()
  PanelKeymap.register()
end

function M.unregister()
  PanelCmds.unregister()
  PanelKeymap.unregister()
end

function M.toggle()
  PanelCmds.toggle()
end

return M
