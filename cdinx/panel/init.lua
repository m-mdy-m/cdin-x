-- CDIN-X Plugin Manager panel.
local Host        = require "cdinx.host"
local Manager     = require "cdinx.manager"
local PanelView   = require "cdinx.panel.view"
local PanelCmds   = require "cdinx.panel.commands"
local PanelKeymap = require "cdinx.panel.keymap"

local M = {}

Host.config.pluginmanager_size = Host.config.pluginmanager_size or 460 * Host.scale
Host.config.pluginmanager_min  = Host.config.pluginmanager_min  or 300 * Host.scale

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

local Features = require "cdinx.manager.features"
local Packages = require "cdinx.packages"

--- The manager's context, for `Features.active`.
---
--- Features are read off the manager's own ctx, because that is the table the
--- runtime registers into -- a second context would answer a question about a
--- session that is not running. It is fetched through the facade rather than
--- required directly, so the panel keeps one way in.
local function ctx() return Manager.context() end

--- A feature as a panel row.
---
--- A feature is not selectable on its own. Pressing space on a *package* has to
--- keep meaning what it has always meant -- install, enable or disable the whole
--- package -- because that is the operation with a lifecycle behind it, and the one
--- users reach for. A feature is a switch inside that package, so it is a detail
--- row: it appears, it can be read, and it is turned from the package's own detail
--- view rather than from the same key that installs something.
---
--- What it does carry here is the *state*, which is the thing that was invisible:
--- before `packages.lua` there was no way for the panel to know a feature was off,
--- because nothing recorded it.
--- @param name string
--- @param plugin table
--- @return table[]
local function feature_rows(name, plugin)
  local out = {}
  local declared = plugin.spec and Features.declared(plugin.spec)
  if not declared or #declared == 0 then return out end

  local overrides = Packages.feature_overrides(name) or {}
  local active = {}
  for _, key in ipairs(Features.active(ctx, name)) do active[key] = true end

  for _, f in ipairs(declared) do
    -- The effective state, not the declared default: an override is what counts,
    -- and a feature with no opinion is on exactly when its default says so.
    local on
    if overrides[f.key] ~= nil then
      on = overrides[f.key] and true or false
    else
      on = f.default and true or false
    end
    out[#out + 1] = {
      kind        = "feature",
      name        = name,
      key         = f.key,
      label       = f.key,
      description = f.description,
      on          = on,
      -- Whether the switch has been touched. A feature that is on because the
      -- package says so is not the user's choice, and drawing the two the same way
      -- would claim credit for a default.
      chosen      = overrides[f.key] ~= nil,
      -- Running now, which is not the same as being switched on: a feature can be
      -- on and have failed to start.
      running     = active[f.key] == true,
    }
  end
  return out
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
      features    = feature_rows(name, plugin),
    }
  end

  table.sort(entries, function(a, b) return a.name < b.name end)
  return entries
end

-- ── the instance ─────────────────────────────────────────────────────────

M.view = PanelView(function()
  return collect(), catalog_notice()
end)
M.view.target_width = Host.config.pluginmanager_size

local node = Host.core.root_view:get_active_node()
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
