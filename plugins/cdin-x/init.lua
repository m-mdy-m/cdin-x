-- cdin-x: the entry point.
--
-- This file is the only thing the host knows about. It is installed as
-- SITE/plugins/cdin-x/init.lua, so the host's plugin loader finds it the
-- same way it finds any other site plugin, and its init() is the one call
-- that starts the manager.
--
-- Deliberately absent: any path assumption. The host has already appended
-- SITE/?.lua and SITE/?/init.lua to package.path by the time a plugin's
-- init() runs, so `require "cdinx"` resolves to SITE/cdinx/init.lua without
-- this file touching package.path. Reaching into package.path here would
-- mean two places deciding where a module lives, and they would eventually
-- disagree.
local VERSION = "0.2.0"

local M = {
  name = "cdin-x",
  version = VERSION,
  description = "CDIN-X extension manager and the optional CDIN extensions",
  author = "cdin Team",
  license = "MIT",
  category = "core",
  type = "plugin",
  essential = false,
  dependencies = {},
  min_cdin_version = "0.5.0",
  tags = { "manager", "extensions" },
}

local booted = false

function M.init(core, config)
  if booted then return end
  booted = true

  local sep = PATHSEP or package.config:sub(1, 1)
  local function join(...)
    local parts = {}
    for i = 1, select("#", ...) do
      local s = tostring((select(i, ...)))
      if i > 1 and #s > 0 and not s:match("[/\\]$") then parts[#parts + 1] = sep end
      parts[#parts + 1] = s
    end
    return table.concat(parts)
  end

  -- Themes first. A persisted config.theme can name a theme that lives in
  -- this site, and the host applies the configured theme before any plugin
  -- has run — so the root has to be registered before bootstrap() picks
  -- plugins up, or the theme would be missing for the first frame.
  require("core.themes").add_root(join(config.site_dir, "X", "themes"))

  local ok, err = require("cdinx").bootstrap()
  if not ok then
    core.log("cdin-x: %s", tostring(err or "bootstrap failed"))
  end
end

function M.unload()
  if not booted then return end
  -- Nothing to unwind: the manager's own registrations belong to the
  -- plugins it loaded, each of which unloads through its own path. Tearing
  -- the manager out from under them would leave their commands and keymaps
  -- registered with nothing to remove them.
  booted = false
end

return M
