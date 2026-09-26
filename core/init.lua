-- CDIN-X runtime bootstrap.

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

  local Manager = require "core.x.manager"
  local ok, err = Manager.bootstrap()
  if not ok then
    booted = false
    return false, err
  end

  local Command = require "core.x.command"
  Command.register()

  require "core.x.panel"

  core.x = cdin_x
  core.log("cdin-x bootstrapped")
  core.log("  built-in: %d", count(Manager.list_builtin()))
  core.log("  installed: %d", count(Manager.list_local()))
  return true
end

function cdin_x.install(name)
  return require("core.x.manager").install(name)
end

function cdin_x.install_local(path)
  return require("core.x.manager").install_local(path)
end

function cdin_x.uninstall(name)
  return require("core.x.manager").uninstall(name)
end

function cdin_x.enable(name)
  return require("core.x.manager").enable(name)
end

function cdin_x.disable(name)
  return require("core.x.manager").disable(name)
end

function cdin_x.refresh()
  return require("core.x.manager").refresh_registry()
end

function cdin_x.update(name)
  return require("core.x.manager").update(name)
end

function cdin_x.clean(dry_run)
  return require("core.x.manager").clean(dry_run)
end

function cdin_x.list()
  return require("core.x.manager").list()
end

function cdin_x.search(query)
  return require("core.x.manager").search(query)
end

function cdin_x.get(name)
  return require("core.x.manager").get(name)
end

function cdin_x.open_readme(name)
  return require("core.x.manager").open_readme(name)
end

return cdin_x
