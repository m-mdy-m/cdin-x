-- CDIN-X runtime bootstrap.
--
-- Required as `require "cdinx"`, from the entry plugin at
-- plugins/cdin-x/init.lua. The host never names this module: cdin only
-- knows that it loads a bundled plugin, a site plugin, and whatever a
-- plugin's init() does. Everything below is reached from that one call.
local core   = require "core"
local cdin_x = {}
local booted = false

local function count(t)
  local n = 0
  for _ in pairs(t or {}) do n = n + 1 end
  return n
end

function cdin_x.bootstrap()
  if booted then return true end
  booted = true

  local Manager = require "cdinx.manager"
  local ok, err = Manager.bootstrap()
  if not ok then
    booted = false
    return false, err
  end

  local Command = require "cdinx.command"
  Command.register()

  require("cdinx.panel").register()

  core.cdinx = cdin_x
  core.log("cdin-x bootstrapped")
  core.log("  built-in: %d", count(Manager.list_builtin()))
  core.log("  installed: %d", count(Manager.list_local()))
  return true
end

function cdin_x.install(name)
  return require("cdinx.manager").install(name)
end

function cdin_x.install_local(path)
  return require("cdinx.manager").install_local(path)
end

function cdin_x.uninstall(name)
  return require("cdinx.manager").uninstall(name)
end

function cdin_x.enable(name)
  return require("cdinx.manager").enable(name)
end

function cdin_x.disable(name)
  return require("cdinx.manager").disable(name)
end

function cdin_x.refresh()
  return require("cdinx.manager").refresh_registry()
end

function cdin_x.update(name)
  return require("cdinx.manager").update(name)
end

function cdin_x.clean(dry_run)
  return require("cdinx.manager").clean(dry_run)
end

function cdin_x.list()
  return require("cdinx.manager").list()
end

function cdin_x.search(query)
  return require("cdinx.manager").search(query)
end

function cdin_x.get(name)
  return require("cdinx.manager").get(name)
end

function cdin_x.open_readme(name)
  return require("cdinx.manager").open_readme(name)
end

return cdin_x
